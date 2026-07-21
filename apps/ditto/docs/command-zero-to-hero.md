mix phx.auth.gen Accounts User users --hashing-lib argon2

1. Context is Clear
"I fixed a bug on T project, under Develop"
"I had a meeting on T project, under Meeting"

Beginning phase:
- Each user can create a project and invite other users for free.
- Collaboration is managed through `project_members`.

Relations:
- `User has_many :projects`
- `User has_many :project_members`
- `Project belongs_to :user`
- `Project has_many :project_members`
- `Project has_many :categories`
- `Category belongs_to :project`
- `TimeEntry belongs_to :user`
- `TimeEntry belongs_to :project`
- `TimeEntry belongs_to :category`

Commands:
mix phx.gen.context Projects Project projects \
  name:string user_id:references:users --no-scope

mix phx.gen.context Projects Category categories \
  name:string project_id:references:projects --no-scope

mix phx.gen.context Projects ProjectMember project_members \
  user_id:references:users \
  project_id:references:projects \
  --no-scope

mix phx.gen.context Tracking TimeEntry time_entries \
  date:date duration:integer note:text \
  user_id:references:users \
  project_id:references:projects \
  category_id:references:categories --no-scope

Why `--no-scope`:
- `phx.gen.auth` sets up scoped contexts by default.
- In scoped mode, the generator already handles user scope internally.
- If you also add `user_id:references:users`, it conflicts with the scope key and raises:
  `Reference :user_id has the same name as the scope schema key`.
- `--no-scope` disables that scoped behavior so you can keep explicit `user_id` fields.

After generation, add uniqueness constraints:
- `projects`: unique on `[:user_id, :name]`
- `categories`: unique on `[:project_id, :name]`
- `project_members`: unique on `[:user_id, :project_id]` (one user can join one project only once)

Migration example:
```elixir
create unique_index(:projects, [:user_id, :name])
create unique_index(:categories, [:project_id, :name])
create unique_index(:project_members, [:user_id, :project_id])
```

`project_members` detail:
- Use this table to support collaboration (many users in one project).
- `projects.user_id` can stay as project owner/creator.
- `project_members` stores membership rows (`user_id`, `project_id`) for owner + invited members.
