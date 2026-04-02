class SchemaController < ApplicationController
  before_action :require_admin

  def index
    conn = ActiveRecord::Base.connection
    @tables = (conn.tables - %w[schema_migrations ar_internal_metadata]).sort.map do |table_name|
      {
        name: table_name,
        columns: conn.columns(table_name),
        indexes: conn.indexes(table_name)
      }
    end
  end
end
