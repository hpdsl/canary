import psycopg2
import subprocess, time
from psycopg2.extras import Json

def main(args):
    initTime = time.time()
    pg_hostname = subprocess.run(['/bin/bash', '-c', "docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' canary-mongodb"], stdout=subprocess.PIPE,stderr=subprocess.PIPE,universal_newlines=True)
    pg_username = "postgres"
    pg_password = "password"
    pg_db = "canary_db"
    #conn = psycopg2.connect(f'host={pg_hostname} user={pg_username} dbname={pg_db}')
    conn = psycopg2.connect(host='172.17.0.6', user='postgres', dbname='canary_db')
    cur = conn.cursor()
    print("CANARY ::> Connection Establish -> Time = {0}.s".format(time.time()-initTime))

    for state in range(100):
        print("CANARY ::> Iteration {0} starting -> Time = {1}.s".format(state, time.time()-initTime))
        cur.execute("select t1.business_id, t1.name, t1.city, t1.state, t1.stars, t1.review_count, count(t2.id) as checkins, sum(t3.cool) as cool_reviews from business_info t1 JOIN checkin_info t2 on t1.business_id=t2.business_id JOIN review_info t3 on t2.business_id=t3.business_id where t1.city ilike 'Pittsburgh' group by t1.business_id order by checkins desc limit 10;")
        print("CANARY ::> Query 1 completed -> Time = {0}.s".format(time.time()-initTime))

        cur.execute("select t1.business_id, t1.name, t1.city, t1.address, t1.review_count, t2.closing_hour, t3.category, t5.stars from business_info t1 JOIN business_hour t2 on t1.business_id=t2.business_id JOIN business_category t3 on t2.business_id=t3.business_id JOIN review_info t5 on t3.business_id=t5.business_id JOIN business_attributes_exploded t4 on t5.business_id=t4.business_id where t1.city='Las Vegas' AND t2.closing_hour > '22:00:00' AND t3.category='Restaurants' AND t5.stars > 3 AND t4.\"GoodForKids\" ilike 'True';")
        print("CANARY ::> Query 2 completed -> Time = {0}.s".format(time.time()-initTime))

        cur.execute("select t1.business_id, t1.name, t1.city, t1.state, t1.address, t1.stars, t2.category from business_info t1 JOIN business_category t2 on t1.business_id=t2.business_id where t1.stars>4 AND t1.state='NY' AND t2.category='Sandwiches' limit 50;")
        print("CANARY ::> Query 3 completed -> Time = {0}.s".format(time.time()-initTime))

        cur.execute("select t1.business_id, t1.name, t1.city, t1.state, t1.address, t1.stars, t1.review_count, t3.category from business_info t1 JOIN review_info t2 on t1.business_id=t2.business_id JOIN business_category t3 on t2.business_id=t3.business_id where t2.date > '2005-01-01 00:00:00' AND t2.date < '2006-01-01 00:00:00' AND t3.category ILIKE '%resort%' GROUP BY t1.business_id, t3.category ORDER BY t1.review_count DESC limit 50;")
        print("CANARY ::> Query 4 completed -> Time = {0}.s".format(time.time()-initTime))

        cur.execute("select t1.business_id, t1.name, t1.city, t1.state, t1.stars, t1.review_count from business_info t1 where is_open=0 and stars <2 limit 10;")
        print("CANARY ::> Query 5 completed -> Time = {0}.s".format(time.time()-initTime))

        cur.execute("select t1.city, t1.state, count(t2.review_id) as total_reviews from business_info t1 JOIN review_info t2 on t1.business_id=t2.business_id group by t1.city,t1.state order by total_reviews desc limit 10; ")
        print("CANARY ::> Query 6 completed -> Time = {0}.s".format(time.time()-initTime))
        print("CANARY ::> State {0} collection -> Time = {1}.s".format(state, time.time()-initTime))

    cur.close()
    conn.commit()
    print("CANARY ::> Job completed -> Time = {0}.s".format(time.time()-initTime))

    return {'CANARY STATUS': "Queries completed successfully."}
