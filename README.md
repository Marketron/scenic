# Scenic

![Scenic Landscape](https://user-images.githubusercontent.com/152152/49344534-a8817480-f646-11e8-8431-3d95d349c070.png)

[![Build Status](https://travis-ci.org/scenic-views/scenic.svg?branch=master)](https://travis-ci.org/scenic-views/scenic)
[![Documentation Quality](http://inch-ci.org/github/scenic-views/scenic.svg?branch=master)](http://inch-ci.org/github/scenic-views/scenic)
[![Reviewed by Hound](https://img.shields.io/badge/Reviewed_by-Hound-8E64B0.svg)](https://houndci.com)

## Roomer specific changes

Roomer is required in this forked version of the gem and will tell you if it doesn't exist in your rails application.

The SQL file, migration file, and migration class are prepended with "(R)roomer" allowing the migration to be run on each tenant without having to specify the schema name or iterate over tenants. 

By using Roomer the views are also automatically added to the schareD_schema.rb and tenanted_schema.rb files via Roomer::Schema.dump in Roomer's rake tasks. 

New directories are created under the shared and tenanted schema locations for the SQL files
```shell script
db/migrate/shared/views
db/migrate/tenanted/views
```  
***

To create a new view in the global schema, run the generator with the "shared=true" option (notice the pluralized name)
```shell script
bundle exec rails generate scenic:view name_of_postgres_view shared=true
```
This will output links in the console to the SQL file for the query and Roomer migration that runs it
```shell script
create  db/migrate/global/views/name_of_postgres_views_v01.sql
create  db/migrate/global/20190926171409_roomer_create_name_of_postgres_views.rb
```
To create a new view in a tenanted schema, run the generator without the shared option
```shell script
bundle exec rails generate scenic:view sc_test_view_mats
```
To update the first view re-run the exact same command as before
```shell script
bundle exec rails generate scenic:view name_of_postgres_view shared=true
```
Which then provides a version 02 of the SQL file with the same query contents for editing and a new migration to drop and create the view
```shell script
create  db/migrate/global/views/name_of_postgres_views_v02.sql
create  db/migrate/global/20190926171420_roomer_update_name_of_postgres_views_to_version_2.rb
```
Not ideal, but you can see the changes between versions using git diff (--word-diff is optional)
```shell script
git diff --no-index --word-diff db/migrate/tenanted/views/name_of_postgres_views_v01.sql db/migrate/tenanted/views/name_of_postgres_views_v02.sql
```
Once you're done making changes run db:migrate like you normally would using Roomer, either db:migrate or specify the shared/tenanted migrate or rollback.

Currently the materialize option does not work as a result of these changes; but you may be able to edit the migration manually and get it to work. The scenic model generator still works but doesn't take Roomer's multi-tenanted environment into account; but it can be modified manually.

Here are the methods with their signatures available in migrations with the inclusion of the scenic gem
```shell script
create_view(name, version: nil, sql_definition: nil, shared: false, materialized: false)
drop_view(name, revert_to_version: nil, shared: false, materialized: false)
update_view(name, version: nil, sql_definition: nil, shared: false, revert_to_version: nil, materialized: false)
replace_view(name, version: nil, shared: false, revert_to_version: nil, materialized: false)
```

Following are the contents of the original scenic readme text.
***

## Original README text

Scenic adds methods to `ActiveRecord::Migration` to create and manage database
views in Rails.

Using Scenic, you can bring the power of SQL views to your Rails application
without having to switch your schema format to SQL. Scenic provides a convention
for versioning views that keeps your migration history consistent and reversible
and avoids having to duplicate SQL strings across migrations. As an added bonus,
you define the structure of your view in a SQL file, meaning you get full SQL
syntax highlighting in the editor of your choice and can easily test your SQL in
the database console during development.

Scenic ships with support for PostgreSQL. The adapter is configurable (see
`Scenic::Configuration`) and has a minimal interface (see
`Scenic::Adapters::Postgres`) that other gems can provide.

## So how do I install this?

If you're using Postgres, Add `gem "scenic"` to your Gemfile and run `bundle
install`. If you're using something other than Postgres, check out the available
[third party adapters](https://github.com/scenic-views/scenic#faqs).

## Great, how do I create a view?

You've got this great idea for a view you'd like to call `search_results`. You
can create the migration and the corresponding view definition file with the
following command:

```sh
$ rails generate scenic:view search_results
      create  db/views/search_results_v01.sql
      create  db/migrate/[TIMESTAMP]_create_search_results.rb
```

Edit the `db/views/search_results_v01.sql` file with the SQL statement that
defines your view. In our example, this might look something like this:

```sql
SELECT
  statuses.id AS searchable_id,
  'Status' AS searchable_type,
  comments.body AS term
FROM statuses
JOIN comments ON statuses.id = comments.status_id

UNION

SELECT
  statuses.id AS searchable_id,
  'Status' AS searchable_type,
  statuses.body AS term
FROM statuses
```

The generated migration will contain a `create_view` statement. Run the
migration, and [baby, you got a view going][carl]. The migration is reversible
and the schema will be dumped into your `schema.rb` file.

[carl]: https://www.youtube.com/watch?v=Sr2PlqXw03Y

```sh
$ rake db:migrate
```

## Cool, but what if I need to change that view?

Here's where Scenic really shines. Run that same view generator once more:

```sh
$ rails generate scenic:view search_results
      create  db/views/search_results_v02.sql
      create  db/migrate/[TIMESTAMP]_update_search_results_to_version_2.rb
```

Scenic detected that we already had an existing `search_results` view at version
1, created a copy of that definition as version 2, and created a migration to
update to the version 2 schema. All that's left for you to do is tweak the
schema in the new definition and run the `update_view` migration.

## What if I want to change a view without dropping it?

The `update_view` statement used by default will drop your view then create
a new version of it.

This is not desirable when you have complicated hierarchies of views, especially
when some of those views may be materialized and take a long time to recreate.

You can use `replace_view` to generate a CREATE OR REPLACE VIEW SQL statement.

See postgresql documentation on how this works:
http://www.postgresql.org/docs/current/static/sql-createview.html

To start replacing a view run the generator like for a regular change:

```sh
$ rails generate scenic:view search_results
      create  db/views/search_results_v02.sql
      create  db/migrate/[TIMESTAMP]_update_search_results_to_version_2.rb
```

Now, edit the migration. It should look something like:

```ruby
class UpdateSearchResultsToVersion2 < ActiveRecord::Migration
  def change
    update_view :search_results, version: 2, revert_to_version: 1
  end
end
```

Update it to use replace view:

```ruby
class UpdateSearchResultsToVersion2 < ActiveRecord::Migration
  def change
    replace_view :search_results, version: 2, revert_to_version: 1
  end
end
```

Now you can run the migration like normal.

## Can I use this view to back a model?

You bet! Using view-backed models can help promote concepts hidden in your
relational data to first-class domain objects and can clean up complex
ActiveRecord or ARel queries. As far as ActiveRecord is concerned, a view is
no different than a table.

```ruby
class SearchResult < ActiveRecord::Base
  belongs_to :searchable, polymorphic: true

  # this isn't strictly necessary, but it will prevent
  # rails from calling save, which would fail anyway.
  def readonly?
    true
  end
end
```

Scenic even provides a `scenic:model` generator that is a superset of
`scenic:view`.  It will act identically to the Rails `model` generator except
that it will create a Scenic view migration rather than a table migration.

There is no special base class or mixin needed. If desired, any code the model
generator adds can be removed without worry.

```sh
$ rails generate scenic:model recent_status
      invoke  active_record
      create    app/models/recent_status.rb
      invoke    test_unit
      create      test/models/recent_status_test.rb
      create      test/fixtures/recent_statuses.yml
      create  db/views/recent_statuses_v01.sql
      create  db/migrate/20151112015036_create_recent_statuses.rb
```

## What about materialized views?

Materialized views are essentially SQL queries whose results can be cached to a
table, indexed, and periodically refreshed when desired. Does Scenic support
those? Of course!

The `scenic:view` and `scenic:model` generators accept a `--materialized`
option for this purpose. When used with the model generator, your model will
have the following method defined as a convenience to aid in scheduling
refreshes:

```ruby
def self.refresh
  Scenic.database.refresh_materialized_view(table_name, concurrently: false, cascade: false)
end
```

This will perform a non-concurrent refresh, locking the view for selects until
the refresh is complete. You can avoid locking the view by passing
`concurrently: true` but this requires both PostgreSQL 9.4 and your view to have
at least one unique index that covers all rows. You can add or update indexes for
materialized views using table migration methods (e.g. `add_index table_name`)
and these will be automatically re-applied when views are updated.

The `cascade` option is to refresh materialized views that depend on other
materialized views. For example, say you have materialized view A, which selects
data from materialized view B. To get the most up to date information in view A
you would need to refresh view B first, then right after refresh view A. If you
would like this cascading refresh of materialized views, set `cascade: true`
when you refresh your materialized view.

## I don't need this view anymore. Make it go away.

Scenic gives you `drop_view` too:

```ruby
def change
  drop_view :search_results, revert_to_version: 2
  drop_view :materialized_admin_reports, revert_to_version: 3, materialized: true
end
```

## FAQs

**Why do I get an error when querying a view-backed model with `find`, `last`, or `first`?**

ActiveRecord's `find` method expects to query based on your model's primary key,
but views do not have primary keys. Additionally, the `first` and `last` methods
will produce queries that attempt to sort based on the primary key.

You can get around these issues by setting the primary key column on your Rails
model like so:

```ruby
class People < ActiveRecord::Base
  self.primary_key = :my_unique_identifier_field
end
```

**Why is my view missing columns from the underlying table?**

Did you create the view with `SELECT [table_name].*`? Most (possibly all)
relational databases freeze the view definition at the time of creation. New
columns will not be available in the view until the definition is updated once
again. This can be accomplished by "updating" the view to its current definition
to bake in the new meaning of `*`.

```ruby
add_column :posts, :title, :string
update_view :posts_with_aggregate_data, version: 2, revert_to_version: 2
```

**When will you support MySQL, SQLite, or other databases?**

We have no plans to add first-party adapters for other relational databases at
this time because we (the maintainers) do not currently have a use for them.
It's our experience that maintaining a library effectively requires regular use
of its features. We're not in a good position to support MySQL, SQLite or other
database users.

Scenic *does* support configuring different database adapters and should be
extendable with adapter libraries. If you implement such an adapter, we're happy
to review and link to it. We're also happy to make changes that would better
accommodate adapter gems.

We are aware of the following existing adapter libraries for Scenic which may
meet your needs:

* [scenic_sqlite_adapter](https://github.com/pdebelak/scenic_sqlite_adapter)
* [scenic-mysql_adapter](https://github.com/EmpaticoOrg/scenic-mysql_adapter)
* [scenic-sqlserver-adapter](https://github.com/ClickMechanic/scenic_sqlserver_adapter)
* [scenic-oracle_enhanced_adapter](https://github.com/PMACS/scenic_oracle_enhanced_adapter)

## About

Scenic is maintained by [Derek Prior], [Caleb Thompson], and you, our
contributors.

[Derek Prior]: http://prioritized.net
[Caleb Thompson]: http://calebthompson.io
