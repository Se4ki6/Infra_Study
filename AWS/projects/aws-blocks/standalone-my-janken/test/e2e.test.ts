/**
 * End-to-end tests — tests the API via direct imports (same typed client the frontend uses).
 *
 * Run:  npm run test:e2e   (dev サーバが起動済みならそれを再利用する)
 */
import { test } from 'node:test';
import assert from 'node:assert';
import { spawn, type ChildProcess } from 'node:child_process';
import { setTimeout } from 'node:timers/promises';
import { installCookieJar, isServerRunning } from '@aws-blocks/blocks/utils';
import type { api as ApiType, authApi as AuthApiType } from 'aws-blocks';

installCookieJar();

let server: ChildProcess | null = null;
let api: typeof ApiType;
let authApi: typeof AuthApiType;

// ─── Setup (don't touch) ─────────────────────────────────────────────────────
test.before(async () => {
  if (!await isServerRunning()) {
    server = spawn('npm', ['run', 'dev:server'], {
      cwd: process.cwd(),
      stdio: ['ignore', 'pipe', 'pipe'],
      detached: true,
      env: { ...process.env, NODE_OPTIONS: '' },
    });
    server.unref();
    await setTimeout(2000);
  }

  const mod = await import('aws-blocks');
  api = mod.api;
  authApi = mod.authApi;

  for (let i = 0; i < 30; i++) {
    try { await authApi.getAuthState(); return; } catch { await setTimeout(1000); }
  }
  throw new Error('Dev server did not become ready within 30s');
});

test.after(() => {
  if (server?.pid) {
    try { process.kill(-server.pid, 'SIGTERM'); } catch {}
  }
});

// ─── じゃんけん (step 1) ────────────────────────────────────────────────────────

// サーバが返した cpuHand と outcome の整合性を、テスト側でも検算する。
const BEATS: Record<string, string> = { rock: 'scissors', scissors: 'paper', paper: 'rock' };
function expectedOutcome(player: string, cpu: string): string {
  if (player === cpu) return 'draw';
  return BEATS[player] === cpu ? 'win' : 'lose';
}

test('playRound: 返り値の形が正しい', async () => {
  const r = await api.playRound('rock');
  assert.strictEqual(r.playerHand, 'rock');
  assert.ok(['rock', 'scissors', 'paper'].includes(r.cpuHand));
  assert.ok(['win', 'lose', 'draw'].includes(r.outcome));
});

test('playRound: cpuHand と outcome が矛盾しない（30回試行）', async () => {
  for (let i = 0; i < 30; i++) {
    const hand = (['rock', 'scissors', 'paper'] as const)[i % 3];
    const r = await api.playRound(hand);
    assert.strictEqual(r.outcome, expectedOutcome(hand, r.cpuHand),
      `${hand} vs ${r.cpuHand} は ${expectedOutcome(hand, r.cpuHand)} のはず`);
  }
});
