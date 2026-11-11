-- 001: initial schema of Ostwind Orbital's manufacturing system (MES)

create table mes.parts (
    part_id        integer generated always as identity primary key,
    part_number    text          not null unique,
    name           text          not null,
    part_family    text          not null
                   check (part_family in ('engine', 'structure', 'avionics', 'propellant_feed')),
    supplier_code  text,                       -- joins to the finance Google Sheet (not enforced)
    unit_cost_eur  numeric(12, 2) not null check (unit_cost_eur >= 0),
    created_at     timestamptz   not null default now(),
    updated_at     timestamptz   not null default now()
);

create table mes.work_orders (
    work_order_id  integer generated always as identity primary key,
    part_id        integer     not null references mes.parts (part_id),
    quantity       integer     not null check (quantity > 0),
    status         text        not null default 'planned'
                   check (status in ('planned', 'released', 'in_progress', 'completed', 'scrapped')),
    planned_start  timestamptz not null,
    planned_end    timestamptz not null,
    actual_start   timestamptz,
    actual_end     timestamptz,
    deleted_at     timestamptz,                -- soft delete: keeps deletes visible to the pipeline
    created_at     timestamptz not null default now(),
    updated_at     timestamptz not null default now()
);

-- Insert-only event log: no updated_at
create table mes.quality_inspections (
    inspection_id  integer generated always as identity primary key,
    work_order_id  integer     not null references mes.work_orders (work_order_id),
    result         text        not null check (result in ('pass', 'fail', 'rework')),
    defect_code    text,                       -- deliberately not enforced: real sources are messy
    inspected_at   timestamptz not null,
    created_at     timestamptz not null default now()
);

create table mes.test_firings (
    firing_id                 integer generated always as identity primary key,
    part_id                   integer       not null references mes.parts (part_id),
    test_stand                text          not null,
    planned_duration_s        integer       not null check (planned_duration_s > 0),
    actual_duration_s         integer,
    outcome                   text check (outcome in ('nominal', 'early_cutoff', 'abort')),
    max_chamber_pressure_bar  numeric(6, 2),
    fired_at                  timestamptz   not null,
    created_at                timestamptz   not null default now(),
    updated_at                timestamptz   not null default now()
);

-- Keep updated_at honest: the database sets it on every UPDATE,
-- even if the application forgets to.
create function mes.set_updated_at() returns trigger language plpgsql as $$
begin
    new.updated_at := now();
    return new;
end;
$$;

create trigger trg_parts_updated_at before update on mes.parts
    for each row execute function mes.set_updated_at();
create trigger trg_work_orders_updated_at before update on mes.work_orders
    for each row execute function mes.set_updated_at();
create trigger trg_test_firings_updated_at before update on mes.test_firings
    for each row execute function mes.set_updated_at();

-- Incremental extraction filters on these columns, so index them
create index idx_parts_updated_at on mes.parts (updated_at);
create index idx_work_orders_updated_at on mes.work_orders (updated_at);
create index idx_quality_inspections_created_at on mes.quality_inspections (created_at);
create index idx_test_firings_updated_at on mes.test_firings (updated_at);
