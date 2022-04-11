import sys
import psycopg2
import json
from psycopg2.extras import Json
# Redundant function
# Used to find nested json keys
def id_generator(dict_var):
    for k, v in dict_var.items():
        v = isinstance(v, str) and v.replace("True", "true").replace("False", "false").replace('"', "'").replace("'", '"')
        try:
            v = json.loads(v)
            print(f'Parsed: {k}: {v}')
        except:
            print(f'Cannot parse {k}: {v}')
            pass
            # Dont show any error
        if isinstance(v, dict):
            for id_val in id_generator(v):
                yield id_val
        else:
            yield k
def process_business_attributes():
    conn = psycopg2.connect(host='172.17.0.6', user='postgres', dbname='canary_db')
    cur = conn.cursor()
    cur.execute("SELECT * FROM business_attribute")
    rows = cur.fetchall()
    ops = []
    for i, r in enumerate(rows):
        isUpdated = False
        attributes = r[1]
        for k, v in attributes.items():
            if isinstance(v, str) and '{' in v and '}' in v:
                # Replace True and False to true and false respectively as these are the standard JSON notations.
                # Replace the single quotes with double and the double ones with single, this is a problem in the source data. JSON data needs to have the keys enclosed in double quotes.
                v = v.replace("True", "true").replace("False", "false").replace('"', "'").replace("'", '"')  
                try:
                    v = json.loads(v)
                    attributes[k] = v
                    isUpdated = True
                except:
                    pass
        if isUpdated:
            ops.append({"business_id": r[0], "attributes": Json(attributes)})
    print(f'Starting to update {len(ops)} rows in business_attribute table...')
    # The following query takes around 50 minutes
    cur.executemany("UPDATE business_attribute SET attribute = %(attributes)s WHERE business_id = %(business_id)s", ops)
    print(f'Updated {len(ops)} rows in business_attributes')
    # This query takes around 13 seconds
    cur.execute(
            """
            CREATE TABLE business_attribute_temp AS (with recursive flat(business_id, key, value) as
            (
                SELECT business_id, key, value FROM business_attribute, jsonb_each(attribute)
                UNION
                SELECT f.business_id, concat(f.key, '.', j.key), j.value FROM flat f, jsonb_each(f.value) j WHERE jsonb_typeof(f.value) = 'object'
            )
            SELECT business_id, jsonb_object_agg(key, value) as data from flat WHERE jsonb_typeof(value) <> 'object' GROUP BY business_id);
            create or replace function create_jsonb_flat_view
                (table_name text, regular_columns text, json_column text)
                returns text language plpgsql as $$
            declare
                cols text;
            begin
                execute format ($ex$
                    select string_agg(format('%2$s->>%%1$L "%%1$s"', key), ', ')
                    from (
                        select distinct key
                        from %1$s, jsonb_each(%2$s)
                        order by 1
                        ) s;
                    $ex$, table_name, json_column)
                into cols;
                execute format($ex$
                    drop view if exists %1$s_view;
                    create view %1$s_view as 
                    select %2$s, %3$s from %1$s
                    $ex$, table_name, regular_columns, cols);
                return cols;
            end $$;
            SELECT create_jsonb_flat_view('business_attribute_temp', 'business_id', 'data');
            CREATE TABLE business_attributes_exploded AS (SELECT * FROM business_attribute_temp_view);
	    ALTER TABLE business_attributes_exploded ADD PRIMARY KEY (business_id);
            """
            )
    cur.close()
    conn.commit()

process_business_attributes()
