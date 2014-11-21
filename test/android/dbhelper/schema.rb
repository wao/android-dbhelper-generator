Android.dbschema do
    create_table( :LoadTest ) do
        primary_key :id
        DateTime :date
    end
end
