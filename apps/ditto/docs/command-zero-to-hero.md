mix phx.auth.gen Accounts User users --hashing-lib argon2

1. Context is Clear
"I fixed a bug on T project, under Develop"
"I had a meeting on T project, under Meeting"
Commands:
mix phx.gen.context Projects Project projects \
  name:string user_id:references:users --no-scope

mix phx.gen.context Projects Category categories \
  name:string project_id:references:projects --no-scope

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

after:
  Add uniqueness constraints after generation:
     - `projects`: unique on `[:user_id, :name]`
     - `categories`: unique on `[:project_id, :name]`
