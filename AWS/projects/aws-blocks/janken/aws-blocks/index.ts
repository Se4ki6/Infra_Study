import { ApiNamespace, Scope, KVStore, AuthBasic } from '@aws-blocks/blocks';
import crypto from 'node:crypto';

// For coding agents: Leave these comments in place for future reference.
// Read node_modules/@aws-blocks/blocks/README.md for all available Building Blocks
// Hover over Building Blocks to see docstrings with usage, best practices, and performance characteristics
const scope = new Scope('janken');

// ── 型定義 ───────────────────────────────────────────────────────────
const HANDS = ['rock', 'scissors', 'paper'] as const;
type Hand = (typeof HANDS)[number];
type Outcome = 'win' | 'lose' | 'draw';

/** 進行中のゲーム。KVStore に `session:{userId}` で保持する。 */
interface Session {
  round: number; // これまでに消化したラウンド数 (0〜10)
  wins: number;  // 勝った回数
}

/** 確定したゲーム結果。ランキング用に `result:{ulid}` で保存する。 */
interface GameResult {
  username: string;
  wins: number;
  playedAt: number;
}

const TOTAL_ROUNDS = 10;

// Building Blocks: 1つのストアを key プレフィックスで分割（session: / result:）。
// session と result で値の形が違うため schema は付けず、型はジェネリックで与える。
const store = new KVStore<Session | GameResult>(scope, 'app-store', {});

const auth = new AuthBasic(scope, 'auth', {
  crossDomain: process.env.BLOCKS_SANDBOX === 'true',
});

// ── じゃんけんロジック（サーバ権威。CPUの手もここで生成する）─────────
const BEATS: Record<Hand, Hand> = {
  rock: 'scissors',   // グー は チョキ に勝つ
  scissors: 'paper',  // チョキ は パー に勝つ
  paper: 'rock',      // パー は グー に勝つ
};

function judge(player: Hand, cpu: Hand): Outcome {
  if (player === cpu) return 'draw';
  return BEATS[player] === cpu ? 'win' : 'lose';
}

function randomHand(): Hand {
  return HANDS[crypto.randomInt(HANDS.length)];
}

/** timestamp 由来でソート可能なユニーク ID。result キーの衝突を防ぐ。 */
function ulid(): string {
  return Date.now().toString(36) + crypto.randomBytes(8).toString('hex');
}

export const authApi = auth.createApi();

export const api = new ApiNamespace(scope, 'api', (context) => ({
  /** 新しい 10 回戦を開始。途中セッションが残っていても常に初期化する。 */
  async startGame(): Promise<{ round: number; wins: number; totalRounds: number }> {
    const user = await auth.requireAuth(context);
    const session: Session = { round: 0, wins: 0 };
    await store.put(`session:${user.username}`, session);
    return { ...session, totalRounds: TOTAL_ROUNDS };
  },

  /** 1 ラウンドぶんプレイ。CPU の手・勝敗・進行状況を返す。 */
  async playRound(hand: Hand): Promise<{
    playerHand: Hand;
    cpuHand: Hand;
    outcome: Outcome;
    round: number;
    wins: number;
    totalRounds: number;
    finished: boolean;
  }> {
    const user = await auth.requireAuth(context);

    if (!HANDS.includes(hand)) {
      throw new Error(`不正な手です: ${hand}`);
    }

    const session = (await store.get(`session:${user.username}`)) as Session | null;
    if (!session) {
      throw new Error('ゲームが開始されていません。先に「ゲーム開始」を押してください。');
    }
    if (session.round >= TOTAL_ROUNDS) {
      throw new Error('このゲームは既に終了しています。');
    }

    const cpuHand = randomHand();
    const outcome = judge(hand, cpuHand);

    session.round += 1;
    if (outcome === 'win') session.wins += 1;

    const finished = session.round >= TOTAL_ROUNDS;
    if (finished) {
      // 結果を確定保存し、進行中セッションを片付ける。
      const result: GameResult = {
        username: user.username,
        wins: session.wins,
        playedAt: Date.now(),
      };
      await store.put(`result:${ulid()}`, result);
      await store.delete(`session:${user.username}`);
    } else {
      await store.put(`session:${user.username}`, session);
    }

    return {
      playerHand: hand,
      cpuHand,
      outcome,
      round: session.round,
      wins: session.wins,
      totalRounds: TOTAL_ROUNDS,
      finished,
    };
  },

  /** ランキング（勝利数の多い順、上位 N 件）。同一ユーザの重複ランクインを許容。 */
  async getRanking(limit: number = 10): Promise<GameResult[]> {
    const results: GameResult[] = [];
    for await (const { key, value } of store.scan()) {
      if (key.startsWith('result:')) {
        results.push(value as GameResult);
      }
    }
    results.sort((a, b) => b.wins - a.wins || a.playedAt - b.playedAt);
    return results.slice(0, limit);
  },
}));
