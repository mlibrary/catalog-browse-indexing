# frozen-string-literal: true
#
# The pg_auto_parameterize_in_array extension builds on the pg_auto_parameterize
# extension, adding support for handling additional types when converting from
# IN to = ANY and NOT IN to != ALL:
#
#   DB[:table].where(column: [1.0, 2.0, ...])
#   # Without extension: column IN ($1::numeric, $2:numeric, ...) # bound variables: 1.0, 2.0, ...
#   # With extension:    column = ANY($1::numeric[]) # bound variables: [1.0, 2.0, ...]
#
# This prevents the use of an unbounded number of bound variables based on the
# size of the array, as well as using different SQL for different array sizes.
#
# The following types are supported when doing the conversions, with the database
# type used:
#
# Float :: if any are infinite or NaN, double precision, otherwise numeric
# BigDecimal :: numeric
# Date :: date
# Time :: timestamp (or timestamptz if pg_timestamptz extension is used)
# DateTime :: timestamp (or timestamptz if pg_timestamptz extension is used)
# Sequel::SQLTime :: time
# Sequel::SQL::Blob :: bytea
# 
# String values are also supported using the +text+ type, but only if the 
# +:treat_string_list_as_text_array+ Database option is used. This is because
# treating strings as text can break programs, since the type for
# literal strings in PostgreSQL is +unknown+, not +text+.
#
# The conversion is only done for single dimensional arrays that have more
# than two elements, where all elements are of the same class (other than
# nil values).
#
# Related module: Sequel::Postgres::AutoParameterizeInArray

module Sequel
  module Postgres
    # Enable automatically parameterizing queries.
    module AutoParameterizeInArray
      # Transform column IN (...) expressions into column = ANY($)
      # and column NOT IN (...) expressions into column != ALL($)
      # using an array bound variable for the ANY/ALL argument,
      # if all values inside the predicate are of the same type and
      # the type is handled by the extension.
      # This is the same optimization PostgreSQL performs internally,
      # but this reduces the number of bound variables.
      def complex_expression_sql_append(sql, op, args)
        case op
        when :IN, :"NOT IN"
          l, r = args
          if auto_param?(sql) && (type = _bound_variable_type_for_array(r))
            if op == :IN 
              op = :"="
              func = :ANY
            else
              op = :!=
              func = :ALL
            end
            args = [l, Sequel.function(func, Sequel.pg_array(r, type))]
          end
        end

        super
      end

      private

      # The bound variable type string to use for the bound variable array.
      # Returns nil if a bound variable should not be used for the array.
      def _bound_variable_type_for_array(r)
        return unless Array === r && r.size > 1
        classes = r.map(&:class)
        classes.uniq!
        classes.delete(NilClass)
        return unless classes.size == 1

        klass = classes[0]
        if klass == Integer
          # This branch is not taken on Ruby <2.4, because of the Fixnum/Bignum split.
          # However, that causes no problems as pg_auto_parameterize handles integer
          # arrays natively (though the SQL used is different)
          "int8"
        elsif klass == String
          "text" if db.typecast_value(:boolean, db.opts[:treat_string_list_as_text_array])
        elsif klass == BigDecimal
          "numeric"
        elsif klass == Date
          "date"
        elsif klass == Time
          @db.cast_type_literal(Time)
        elsif klass == Float
          # PostgreSQL treats literal floats as numeric, not double precision
          # But older versions of PostgreSQL don't handle Infinity/NaN in numeric
          r.all?{|v| v.nil? || v.finite?} ? "numeric" : "double precision"
        elsif klass == Sequel::SQLTime
          "time"
        elsif klass == DateTime
          @db.cast_type_literal(DateTime)
        elsif klass == Sequel::SQL::Blob
          "bytea"
        end
      end
    end
  end

  Database.register_extension(:pg_auto_parameterize_in_array) do |db|
    db.extension(:pg_array, :pg_auto_parameterize)
    db.extend_datasets(Postgres::AutoParameterizeInArray)
  end
end
