mix phx.auth.gen Accounts User users --hashing-lib argon2

1. Context is Clear
"I fixed a bug on T project, under Develop"
"I had a meeting on T project, under Meeting"
Commands:
mix phx.gen.context Projects Project projects \
  name:string user_id:references:users

mix phx.gen.context Projects Category categories \
  name:string project_id:references:projects

mix phx.gen.context Tracking TimeEntry time_entries \
  date:date duration:integer note:text \
  user_id:references:users \
  project_id:references:projects \
  category_id:references:categories
after:
  Add uniqueness constraints after generation:
     - `projects`: unique on `[:user_id, :name]`
     - `categories`: unique on `[:project_id, :name]
