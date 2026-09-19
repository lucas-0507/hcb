-- ═══════════════════════════════════════════════════════════════
-- HCB 主页 · Supabase 落地脚本（在 Supabase 控制台 → SQL Editor 里整段执行）
-- 用法：登录 supabase.com → 你的项目 → SQL Editor → New query → 粘贴执行
-- ═══════════════════════════════════════════════════════════════

-- ────────────────────────────────────────────────
-- 表 1：messages —— 主页公共留言板（访客可看可写）
-- ────────────────────────────────────────────────
create table if not exists public.messages (
  id bigint generated always as identity primary key,
  name text not null default '匿名' check (char_length(name) between 1 and 20),
  message text not null check (char_length(message) between 1 and 500),
  created_at timestamptz not null default now()
);

alter table public.messages enable row level security;

-- 所有人（匿名访客）都可以读公共留言
create policy "messages_anon_read" on public.messages
  for select to anon using (true);

-- 所有人（匿名访客）都可以发布留言
create policy "messages_anon_insert" on public.messages
  for insert to anon with check (true);

-- 不开放 update / delete —— 访客只能写不能改不能删
-- （站主如需删除，在控制台 Table Editor 手动删即可）


-- ────────────────────────────────────────────────
-- 表 2：feedback —— 私有反馈（访客只能提交，只有站主能看）
-- ────────────────────────────────────────────────
create table if not exists public.feedback (
  id bigint generated always as identity primary key,
  name text not null default '匿名' check (char_length(name) between 1 and 20),
  relation text,                    -- 与站主的关系（可选）
  device text,                      -- 针对的设备（可选）
  message text not null check (char_length(message) between 1 and 1000),
  version text,                     -- 提交时页面自动附带，如 index4.1
  created_at timestamptz not null default now()
);

alter table public.feedback enable row level security;

-- 访客只能提交（INSERT），完全不能读（无 select 策略 → 默认拒绝）
create policy "feedback_anon_insert" on public.feedback
  for insert to anon with check (true);

-- ⚠️ 关键：这里【故意】不建任何 select 策略
-- → 匿名访客（包括前端代码里的 anon key）永远读不到 feedback 表
-- → 你（站主）登录 Supabase 控制台 → Table Editor → feedback 即可查看
-- → 如需程序化导出，用服务端 secret key（service_role，绝不放前端）


-- ────────────────────────────────────────────────
-- 表 3：footprints —— 足迹页（访客只读，只有站主能写）
-- ────────────────────────────────────────────────
create table if not exists public.footprints (
  id bigint generated always as identity primary key,
  date text,                        -- 日期/时间标签，如 2026.09.12
  content text not null check (char_length(content) between 1 and 500),
  emotion text,                     -- 可选：心情/表情标签
  created_at timestamptz not null default now()
);

alter table public.footprints enable row level security;

-- 所有人（匿名访客）都可以读足迹
create policy "footprints_anon_read" on public.footprints
  for select to anon using (true);

-- ⚠️ 关键：这里【故意】不建任何 insert / update / delete 策略
-- → 访客只能看，不能写、不能改、不能删
-- → 你更新足迹：Supabase 控制台 → Table Editor → footprints 手动加行
--   （或日后用 service_role / 登录后写，绝不放 anon key 进前端写权限）


-- ────────────────────────────────────────────────
-- 验证（可选，执行后检查是否全部成功）
-- ────────────────────────────────────────────────
select schemaname, tablename, policyname, cmd, roles
from pg_policies
where tablename in ('messages', 'feedback', 'footprints')
order by tablename, policyname;
