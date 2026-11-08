/**
 * Backend — aws-blocks/index.ts  (じゃんけん / step 1: 判定ロジックだけ)
 *
 * フロントは `import { api } from 'aws-blocks'` でここの export を直接呼ぶ。
 * まずは「1回だけじゃんけんして勝敗を返す」最小版。
 * この後のステップで「ログイン必須」「10回戦の記録」「ランキング」を足していく。
 */
import { ApiNamespace, Scope, AuthBasic } from '@aws-blocks/blocks';

const scope = new Scope('my-janken');

// ─── Auth（あなたが設定済み。今ステップではまだ使わない。次ステップで使う）──────
const auth = new AuthBasic(scope, 'auth', {
  passwordPolicy: { minLength: 5 },
  crossDomain: process.env.BLOCKS_SANDBOX === 'true',
});
export const authApi = auth.createApi();

// ─── じゃんけんのルール（サーバ側に置く＝CPUの手も勝敗もサーバが決める）──────
// 手は3種類。`as const` で「この3つの文字列だけ」という厳密な型にする。
const HANDS = ['rock', 'scissors', 'paper'] as const;
type Hand = (typeof HANDS)[number];        // 'rock' | 'scissors' | 'paper'
type Outcome = 'win' | 'lose' | 'draw';    // プレイヤーから見た結果

// 「key の手は value の手に勝つ」という対応表。
// グー(rock)はチョキ(scissors)に勝つ… という関係。
const BEATS: Record<Hand, Hand> = {
  rock: 'scissors',
  scissors: 'paper',
  paper: 'rock',
};

// プレイヤーの手とCPUの手から勝敗を判定する純粋関数。
function judge(player: Hand, cpu: Hand): Outcome {
  if (player === cpu) return 'draw';                 // 同じ＝あいこ
  return BEATS[player] === cpu ? 'win' : 'lose';     // 自分が相手に勝てる関係なら win
}

// CPUの手をランダムに1つ選ぶ。
function randomHand(): Hand {
  return HANDS[Math.floor(Math.random() * HANDS.length)];
}

// ─── API（フロントから api.playRound('rock') のように呼べる）──────────────────
export const api = new ApiNamespace(scope, 'api', (context) => ({

  // 1回だけじゃんけん。プレイヤーの手を受け取り、CPUの手と勝敗を返す。
  // ※まだログイン不要・記録なし。動作確認できる最小単位。
  async playRound(hand: Hand) {
    const cpuHand = randomHand();
    const outcome = judge(hand, cpuHand);
    return { playerHand: hand, cpuHand, outcome };
  },
}));
