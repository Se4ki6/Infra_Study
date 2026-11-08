// Direct import from backend - types available in IDE, Proxy injected at runtime
import { api, authApi } from 'aws-blocks';
import { Authenticator, onAuthChange } from '@aws-blocks/blocks/ui';

// For coding agents: Leave this comment in place for future reference.
// Read node_modules/@aws-blocks/blocks/README.md for Building Block documentation

type Hand = 'rock' | 'scissors' | 'paper';

let currentUser: { username: string } | null = null;
let playing = false; // 1ラウンドの通信中はボタンを二重押しさせない

const HAND_EMOJI: Record<Hand, string> = { rock: '✊', scissors: '✌️', paper: '✋' };
const OUTCOME_LABEL: Record<string, string> = { win: 'WIN 🎉', lose: 'LOSE 😢', draw: 'DRAW 🤝' };

const $ = (id: string) => document.getElementById(id)!;

function setHandsEnabled(enabled: boolean) {
  document.querySelectorAll<HTMLButtonElement>('.hand-buttons button')
    .forEach((b) => (b.disabled = !enabled));
}

function showProgress(round: number, wins: number, total: number) {
  $('progress').textContent = `第 ${round} / ${total} 戦　勝利数: ${wins}`;
}

// ── ゲーム開始 ────────────────────────────────────────────────────────
(window as any).startGame = async () => {
  $('game-error').textContent = '';
  $('round-result').textContent = '';
  $('final-result').textContent = '';
  try {
    const state = await api.startGame();
    showProgress(state.round, state.wins, state.totalRounds);
    setHandsEnabled(true);
    ($('start-button') as HTMLButtonElement).classList.add('hidden');
  } catch (e: any) {
    $('game-error').textContent = e.message;
  }
};

// ── 1ラウンドをプレイ ─────────────────────────────────────────────────
(window as any).play = async (hand: Hand) => {
  if (playing) return;
  playing = true;
  setHandsEnabled(false);
  $('game-error').textContent = '';

  try {
    const r = await api.playRound(hand);
    $('round-result').textContent =
      `あなた ${HAND_EMOJI[r.playerHand]} － ${HAND_EMOJI[r.cpuHand]} CPU　→ ${OUTCOME_LABEL[r.outcome]}`;
    showProgress(r.round, r.wins, r.totalRounds);

    if (r.finished) {
      $('final-result').textContent = `🏁 終了！ 10戦中 ${r.wins} 勝でした`;
      ($('start-button') as HTMLButtonElement).textContent = 'もう一度プレイ';
      ($('start-button') as HTMLButtonElement).classList.remove('hidden');
      await refreshRanking();
    } else {
      setHandsEnabled(true);
    }
  } catch (e: any) {
    $('game-error').textContent = e.message;
    setHandsEnabled(true);
  } finally {
    playing = false;
  }
};

// ── ランキング描画 ────────────────────────────────────────────────────
async function refreshRanking() {
  const el = $('ranking');
  try {
    const ranking = await api.getRanking(10);
    if (ranking.length === 0) {
      el.innerHTML = '<p>まだ記録がありません。最初の挑戦者になりましょう！</p>';
      return;
    }
    const rows = ranking.map((r, i) => `
      <tr>
        <td>${i + 1}</td>
        <td>${escapeHtml(r.username)}</td>
        <td class="num">${r.wins} 勝</td>
        <td>${new Date(r.playedAt).toLocaleString('ja-JP')}</td>
      </tr>`).join('');
    el.innerHTML = `
      <table>
        <thead><tr><th>順位</th><th>ユーザー</th><th>勝利数</th><th>日時</th></tr></thead>
        <tbody>${rows}</tbody>
      </table>`;
  } catch (e: any) {
    el.innerHTML = `<span class="error">${e.message}</span>`;
  }
}

function escapeHtml(s: string): string {
  return s.replace(/[&<>"']/g, (c) =>
    ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]!));
}

// ── 初期化 ────────────────────────────────────────────────────────────
document.addEventListener('DOMContentLoaded', async () => {
  const authContainer = $('auth-container');
  authContainer.appendChild(Authenticator(authApi));

  onAuthChange(authApi, async (user) => {
    currentUser = user;
    $('auth-status').textContent = user ? `ログイン中: ${user.username}` : '未ログイン';

    if (user) {
      $('game-locked').classList.add('hidden');
      $('game-area').classList.remove('hidden');
      // ログイン直後はゲーム未開始。開始ボタンを出し、手は押せない状態に。
      setHandsEnabled(false);
      $('progress').textContent = '「ゲーム開始」を押してスタート';
      ($('start-button') as HTMLButtonElement).textContent = 'ゲーム開始';
      ($('start-button') as HTMLButtonElement).classList.remove('hidden');
      $('round-result').textContent = '';
      $('final-result').textContent = '';
    } else {
      $('game-locked').classList.remove('hidden');
      $('game-area').classList.add('hidden');
    }
  });

  // ランキングはログイン前でも表示
  await refreshRanking();
});

console.log('じゃんけん 10番勝負 loaded');
