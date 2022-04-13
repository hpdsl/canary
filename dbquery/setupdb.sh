#!/bin/bash

echo "Starting program"
echo "Using default user postgres"
#rm -rf /tmp/canary
#echo "Creating directories"
#mkdir /tmp/canary
#echo "Downloading IMDB Dataset"
#cd /tmp/canary
#wget -A "*tsv.gz" --mirror "https://datasets.imdbws.com/" > /dev/null 2>&1
#echo "Extracting the database"
#gunzip datasets.imdbws.com/*.gz
#rm datasets.imdbws.com/robots.txt.tmp
echo "Cleaning up old data"
psql -U postgres -c "DROP DATABASE IF EXISTS canary_db;"
echo "Creating Database"
psql -U postgres -c "CREATE DATABASE canary_db OWNER postgres;"
echo "Assigning Privilages to Postgres User"
psql -U postgres -c "GRANT all privileges on database canary_db to postgres;"
echo "Creating Tables"
psql -U postgres -d canary_db -c "CREATE TABLE business_info (business_id text, name text, address text, city text, state text, postal_code text, latitude float, longitude float, stars float, review_count integer, is_open integer, attributes jsonb, categories text, hours jsonb);"
psql -U postgres -d canary_db -c "CREATE TABLE review_info (review_id text, user_id text, business_id text, stars float, date timestamp, text text, useful integer, funny integer, cool integer);"
psql -U postgres -d canary_db -c "CREATE TABLE user_info (user_id text, name text, review_count text, yelping_since timestamp, friends text, useful integer, funny integer, cool integer, fans integer, elite text, average_stars float, compliment_hot integer, compliment_more integer, compliment_profile integer, compliment_cute integer, compliment_list integer, compliment_note integer, compliment_plain integer, compliment_cool integer, compliment_funny integer, compliment_writer integer, compliment_photos integer);"
psql -U postgres -d canary_db -c "CREATE TABLE checkin (business_id text, date text);"
psql -U postgres -d canary_db -c "CREATE TABLE tip_info (text text, id serial, date timestamp, compliment_count integer, business_id text, user_id text);"
psql -U postgres -d canary_db -c "CREATE TABLE business_attribute (business_id text, attribute jsonb);"

echo "Creating temporary tables"
psql -U postgres -d canary_db -c "create table temp_user_info ( values jsonb);"
psql -U postgres -d canary_db -c "create table temp_checkin_info ( values jsonb);"
psql -U postgres -d canary_db -c "create table temp_tip_info ( values jsonb);"
psql -U postgres -d canary_db -c "create table temp_business_info ( values jsonb);"
psql -U postgres -d canary_db -c "create table temp_review_info ( values jsonb);"

echo "Loading dataset into temp tables"
psql -U postgres -d canary_db -c "copy temp_user_info from '/tmp/canary/user.json' csv quote e'\x01' delimiter e'\x02';"
psql -U postgres -d canary_db -c "copy temp_checkin_info from '/tmp/canary/checkin.json' csv quote e'\x01' delimiter e'\x02';"
psql -U postgres -d canary_db -c "copy temp_tip_info from '/tmp/canary/tip.json' csv quote e'\x01' delimiter e'\x02';"
psql -U postgres -d canary_db -c "copy temp_business_info from '/tmp/canary/business.json' csv quote e'\x01' delimiter e'\x02';"
psql -U postgres -d canary_db -c "copy temp_review_info from '/tmp/canary/review.json' csv quote e'\x01' delimiter e'\x02';"


echo "Loading dataset into final tables"
psql -U postgres -d canary_db -c "insert into checkin (business_id, date) select values->>'business_id' as business_id, values->>'date' as date from (select values from temp_checkin_info) as a;"
psql -U postgres -d canary_db -c "insert into tip_info (text, date, compliment_count, business_id, user_id) select values->>'text' as text, (values->>'date')::timestamp as date, (values->>'compliment_count')::int as compliment_count, values->>'business_id' as business_id,  values->>'user_id' as user_id from (select values from temp_tip_info) as a;"
psql -U postgres -d canary_db -c "insert into business_info (business_id, name, address, city, state, postal_code, latitude, longitude, stars, review_count, is_open, attributes, categories, hours) select values->>'business_id' as business_id, values->>'name' as name, values->>'address' as address, values->>'city' as city, values->>'state' as state, values->>'postal_code' as postal_code, (values->>'latitude')::float as latitude, (values->>'longitude')::float as longitude, (values->>'stars')::float as stars, (values->>'review_count')::int as review_count, (values->>'is_open')::int as is_open, (values->>'attributes')::jsonb as attributes, values->>'categories' as categories, (values->>'hours')::jsonb as hours from (select values from temp_business_info) as a;"
psql -U postgres -d canary_db -c "insert into user_info (user_id, name, review_count, yelping_since, friends, useful, funny, cool, fans, elite, average_stars, compliment_hot, compliment_more, compliment_profile, compliment_cute, compliment_list, compliment_note, compliment_plain, compliment_cool, compliment_funny, compliment_writer, compliment_photos) select values->>'user_id' as user_id, values->>'name' as name, (values->>'review_count')::int as review_count, (values->>'yelping_since')::timestamp as yelping_since, values->>'friends' as friends, (values->>'useful')::int as useful, (values->>'funny')::int as funny, (values->>'cool')::int as cool, (values->>'fans')::int as fans, values->>'elite' as elite, (values->>'average_stars')::float as average_stars, (values->>'compliment_hot')::int as compliment_hot, (values->>'compliment_more')::int as compliment_more, (values->>'compliment_profile')::int as compliment_profile, (values->>'compliment_cute')::int as compliment_cute, (values->>'compliment_list')::int as compliment_list, (values->>'compliment_note')::int as compliment_note, (values->>'compliment_plain')::int as compliment_plain, (values->>'compliment_cool')::int as compliment_cool, (values->>'compliment_funny')::int as compliment_funny, (values->>'compliment_writer')::int as compliment_writer, (values->>'compliment_photos')::int as compliment_photos from (select values from temp_user_info) as a;"
psql -U postgres -d canary_db -c "insert into review_info (review_id, user_id, business_id, stars, date, text, useful, funny, cool) select values->>'review_id' as review_id, values->>'user_id' as user_id, values->>'business_id' as business_id, (values->>'stars')::float as stars, (values->>'date')::timestamp as date, values->>'text' as text, (values->>'useful')::int as useful, (values->>'funny')::int as funny, (values->>'cool')::int as cool from (select values from temp_review_info) as a;"

echo "Performing database sanitization"
psql -U postgres -d canary_db -c "CREATE TABLE business_category(business_id text, id serial, category text);"
psql -U postgres -d canary_db -c "INSERT INTO business_category(business_id,category) SELECT business_id,regexp_split_to_table(categories,', ') from business_info;"
#psql -U postgres -d canary_db -c "CREATE TABLE business_category(business_id,category) AS SELECT business_id,regexp_split_to_table(categories,', ') from business_info;"
psql -U postgres -d canary_db -c "ALTER TABLE business_info drop column categories;"
psql -U postgres -d canary_db -c "CREATE TABLE friend_info(user_id,friend_id) AS SELECT user_id,regexp_split_to_table(friends,', ') from user_info;"
psql -U postgres -d canary_db -c "ALTER TABLE user_info drop column friends;"
psql -U postgres -d canary_db -c "CREATE TABLE checkin_info(business_id text, id serial, date timestamp);"
psql -U postgres -d canary_db -c "INSERT INTO checkin_info(business_id,date) SELECT business_id,(regexp_split_to_table(date,', '))::timestamp from checkin;"
psql -U postgres -d canary_db -c "DROP table checkin;"
# psql -U postgres -d canary_db -c "delete FROM friend_info WHERE NOT EXISTS (SELECT * FROM user_info WHERE user_id=friend_info.friend_id);"
psql -U postgres -d canary_db -c "create table business_hour(business_id text, day text, open_hour time, closing_hour time);"
psql -U postgres -d canary_db -c "insert into business_hour(business_id,day,open_hour,closing_hour) select business_id,'Monday',(split_part(hours->>'Monday','-',1))::time as open_hour, (split_part(hours->>'Monday','-',2))::time as closing_hour from business_info WHERE hours is not null;"
psql -U postgres -d canary_db -c "insert into business_hour(business_id,day,open_hour,closing_hour) select business_id,'Tuesday',(split_part(hours->>'Tuesday','-',1))::time as open_hour, (split_part(hours->>'Tuesday','-',2))::time as closing_hour from business_info WHERE hours is not null;"
psql -U postgres -d canary_db -c "insert into business_hour(business_id,day,open_hour,closing_hour) select business_id,'Wednesday',(split_part(hours->>'Wednesday','-',1))::time as open_hour, (split_part(hours->>'Wednesday','-',2))::time as closing_hour from business_info WHERE hours is not null;"
psql -U postgres -d canary_db -c "insert into business_hour(business_id,day,open_hour,closing_hour) select business_id,'Thursday',(split_part(hours->>'Thursday','-',1))::time as open_hour, (split_part(hours->>'Thursday','-',2))::time as closing_hour from business_info WHERE hours is not null;"
psql -U postgres -d canary_db -c "insert into business_hour(business_id,day,open_hour,closing_hour) select business_id,'Friday',(split_part(hours->>'Friday','-',1))::time as open_hour, (split_part(hours->>'Friday','-',2))::time as closing_hour from business_info WHERE hours is not null;"
psql -U postgres -d canary_db -c "insert into business_hour(business_id,day,open_hour,closing_hour) select business_id,'Saturday',(split_part(hours->>'Saturday','-',1))::time as open_hour, (split_part(hours->>'Saturday','-',2))::time as closing_hour from business_info WHERE hours is not null;"
psql -U postgres -d canary_db -c "insert into business_hour(business_id,day,open_hour,closing_hour) select business_id,'Sunday',(split_part(hours->>'Sunday','-',1))::time as open_hour, (split_part(hours->>'Sunday','-',2))::time as closing_hour from business_info WHERE hours is not null;"
psql -U postgres -d canary_db -c "ALTER TABLE business_info drop column hours;"
psql -U postgres -d canary_db -c "DELETE FROM tip_info ti1 USING tip_info ti2 WHERE ti1.date=ti2.date AND ti1.user_id=ti2.user_id AND ti1.business_id=ti2.business_id and ti1.id<ti2.id;"
psql -U postgres -d canary_db -c "insert into business_attribute(business_id,attribute) select business_id,attributes from business_info WHERE attributes is not null;"
psql -U postgres -d canary_db -c "ALTER TABLE business_info drop column attributes;"
psql -U postgres -d canary_db -c "DELETE FROM business_category bc1 USING business_category bc2 WHERE bc1.business_id=bc2.business_id AND bc1.category=bc2.category AND bc1.id<bc2.id;"

psql -U postgres -d canary_db -c "DELETE FROM review_info WHERE user_id='u8cq-5zzD7dPSa3LR8rIMw'";

psql -U postgres -d canary_db -c "CREATE TABLE elite_info(user_id,elite_year) AS SELECT user_id,regexp_split_to_table(elite,', ') from user_info WHERE elite is not null;"
psql -U postgres -d canary_db -c "ALTER TABLE user_info drop column elite;"

echo "Creating relationships"
psql -U postgres -d canary_db -c "ALTER TABLE business_info ADD PRIMARY KEY (business_id);"
psql -U postgres -d canary_db -c "ALTER TABLE user_info ADD PRIMARY KEY (user_id);"
psql -U postgres -d canary_db -c "ALTER TABLE review_info ADD PRIMARY KEY (review_id);"
psql -U postgres -d canary_db -c "ALTER TABLE business_attribute ADD PRIMARY KEY (business_id,attribute);"
psql -U postgres -d canary_db -c "ALTER TABLE business_category ADD PRIMARY KEY (business_id,category);"
psql -U postgres -d canary_db -c "ALTER TABLE business_hour ADD PRIMARY KEY (business_id,day);"
psql -U postgres -d canary_db -c "ALTER TABLE business_hour ADD CONSTRAINT business_hour_fk FOREIGN KEY (business_id) REFERENCES business_info (business_id);"
psql -U postgres -d canary_db -c "ALTER TABLE business_category ADD CONSTRAINT business_category_fk FOREIGN KEY (business_id) REFERENCES business_info (business_id);"
psql -U postgres -d canary_db -c "ALTER TABLE business_attribute ADD CONSTRAINT business_attribute_fk FOREIGN KEY (business_id) REFERENCES business_info (business_id);"
psql -U postgres -d canary_db -c "ALTER TABLE review_info ADD CONSTRAINT review_business_fk FOREIGN KEY (business_id) REFERENCES business_info (business_id);"
# psql -U postgres -d canary_db -c "ALTER TABLE review_info ADD CONSTRAINT review_user_fk FOREIGN KEY (user_id) REFERENCES user_info (user_id);"

psql -U postgres -d canary_db -c "ALTER TABLE friend_info ADD PRIMARY KEY (user_id,friend_id);"
psql -U postgres -d canary_db -c "ALTER TABLE friend_info ADD CONSTRAINT friend_user_fk FOREIGN KEY (user_id) REFERENCES user_info (user_id);"
#psql -U postgres -d canary_db -c "ALTER TABLE friend_info ADD CONSTRAINT friend_friend_fk FOREIGN KEY (friend_id) REFERENCES user_info (user_id);"

psql -U postgres -d canary_db -c "ALTER TABLE checkin_info ADD PRIMARY KEY (business_id,id);"
psql -U postgres -d canary_db -c "ALTER TABLE tip_info ADD PRIMARY KEY (user_id,business_id,date);"
psql -U postgres -d canary_db -c "ALTER TABLE tip_info ADD CONSTRAINT tip_user_fk FOREIGN KEY (user_id) REFERENCES user_info (user_id);"
psql -U postgres -d canary_db -c "ALTER TABLE tip_info ADD CONSTRAINT tip_business_fk FOREIGN KEY (business_id) REFERENCES business_info (business_id);"

#psql -U postgres -d canary_db -c "ALTER TABLE elite_info ADD PRIMARY KEY (user_id,elite_year);"
#psql -U postgres -d canary_db -c "ALTER TABLE elite_info ADD CONSTRAINT elite_user_fk FOREIGN KEY (user_id) REFERENCES user_info (user_id);"

psql -U postgres -d canary_db -c "DROP table temp_user_info;"
psql -U postgres -d canary_db -c "DROP table temp_checkin_info;"
psql -U postgres -d canary_db -c "DROP table temp_tip_info;"
psql -U postgres -d canary_db -c "DROP table temp_business_info;"
psql -U postgres -d canary_db -c "DROP table temp_review_info;"

psql -U postgres -d canary_db -c "CREATE TABLE elite_info_expanded AS (SELECT user_id, regexp_split_to_table(elite_year, ',') AS year FROM elite_info WHERE elite_year!='' AND elite_year IS NOT NULL);"
psql -U postgres -d canary_db -c "DROP table elite_info;"
psql -U postgres -d canary_db -c "DELETE  FROM elite_info_expanded a USING elite_info_expanded b WHERE a.user_id = b.user_id AND a.year = b.year;"
psql -U postgres -d canary_db -c "ALTER TABLE elite_info_expanded ADD PRIMARY KEY (user_id,year);"
psql -U postgres -d canary_db -c "ALTER TABLE elite_info_expanded ADD CONSTRAINT elite_user_fk FOREIGN KEY (user_id) REFERENCES user_info (user_id);"

echo "Before proceding to running QUERIES, please run proj_p2_t5.py file as mentioned in the README file."
