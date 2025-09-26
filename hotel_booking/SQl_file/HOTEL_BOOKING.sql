create table hotels(hotel_id INT PRIMARY KEY,
                    hotel_name VARCHAR(50),
					city VARCHAR(50),	
					country VARCHAR(50),
					star_rating INT,
					lat REAL,
					lon REAL,
					cleanliness_base DECIMAL(10,2),
					comfort_base DECIMAL(10,2),
					facilities_base DECIMAL(10,2),
					location_base DECIMAL(10,2),
					staff_base DECIMAL(10,2),
					value_for_money_base DECIMAL(10,2)
);
create table users(user_id INT PRIMARY KEY,
                   user_gender VARCHAR(10),
				   country VARCHAR(50),
				   age_group TEXT,
				   traveller_type VARCHAR(50),
				   join_date DATE

);
create table reviews(review_id INT PRIMARY KEY,
                     user_id INT REFERENCES users(user_id),
					 hotel_id INT REFERENCES hotels(hotel_id),
					 review_date DATE,
					 score_overall DECIMAL(10,2),
					 score_cleanliness DECIMAL(10,2),
					 score_comfort DECIMAL(10,2),
					 score_facilities DECIMAL(10,3),
					 score_location DECIMAL(10,2),
					 score_staff DECIMAL(10,2),
					 score_value_for_money DECIMAL(10,2),
					 review_text TEXT

);

COPY hotels from 'D:\postgres\Projects\hotel_booking\hotels.csv' DELIMITER ',' CSV HEADER;
COPY users from 'D:\postgres\Projects\hotel_booking\users.csv' DELIMITER ',' CSV HEADER;
COPY reviews from 'D:\postgres\Projects\hotel_booking\reviews.csv' DELIMITER ',' CSV HEADER;


---QUETION AND ANSWERS---
---1.List all hotels in a specific city (say Mumbai) with their star ratings.
SELECT HOTEL_NAME, STAR_RATING FROM HOTELS WHERE CITY='London';

---2.Find the top 5 youngest users who have written reviews.
SELECT u.user_id, u.age_group,r.review_text from users as u
left join reviews as r on u.user_id=r.user_id
order by u.age_group asc limit 5;

---3.Show all reviews for a given hotel, ordered by review_date.
select h.hotel_name, r.review_date,r.review_text from hotels as h
left join reviews as r on r.hotel_id= r.hotel_id
order by r.review_date asc;

---4.Count how many users belong to each country.
SELECT country,COUNT(user_id) from users group by country ;

---5.Find the most common traveller_type among users.
SELECT traveller_type, count(user_id) from users group by traveller_type order by count(user_id) desc;


---6.Find the top 10 hotels with the highest average score_overall.
select  h.hotel_name,AVG( r.score_overall)as AVG_score_overall from hotels as h
left join reviews as r on h.hotel_id= r.hotel_id
group by h.hotel_name order by AVG_score_overall desc limit 10;

---7.Show the average score_cleanliness per city.
select h.city ,AVG( r.score_cleanliness) as AVG_score_clinliness from hotels as h
left join reviews as r on h.hotel_id=r.hotel_id
GROUP BY h.city order by AVG_score_clinliness desc ;

---8.Find the users who wrote more than 5 reviews.
select  u.user_id , count(r.review_text) as more_than_5_review from users as u
left join reviews as r on u.user_id=r.user_id
group by u.user_id having count(r.review_text) > 5 ;

---9.For each hotel, calculate the difference between its star_rating 
---  and its average score_overall from reviews
select h.hotel_id,h.hotel_name,h.star_rating,
ROUND(AVG(r.score_overall),2) as review_score,
h.star_rating- ROUND(AVG(r.score_overall),2) as difference from hotels as h
join reviews as r on h.hotel_id=r.hotel_id
group by h.hotel_id, h.hotel_name,h.star_rating order by difference DESC;

---10.List hotels where the average score_value_for_money is below the hotel’s value_for_money_base.
select h.hotel_id,h.hotel_name, h.value_for_money_base,ROUND(AVG(score_value_for_money),2) as
Avg_score_value_for_money FROM hotels  as h
join reviews as r on h.hotel_id=r.hotel_id
group by h.hotel_id,h.hotel_name,h.value_for_money_base
having ROUND(AVG(score_value_for_money),2)< h.value_for_money_base;


---11.Find the most frequently reviewed hotel in each country.
with hotel_review_count as(
select h.hotel_id,h.hotel_name,h.country,
count(r.review_id) as total_review ,
rank()over(partition by h.country order by count(r.review_id) desc) as rank_in_country
from hotels as h
join reviews as r on h.hotel_id=r.hotel_id
group by h.hotel_id,h.hotel_name,h.country)
select hotel_id,hotel_name,country,total_review
from hotel_review_count
where rank_in_country =1
order by country;

---12.Identify the top 5 hotels that are rated highest by "Family" traveller_type users.
select h.hotel_name,u.traveller_type ,round(avg(r.score_overall)) as avg_rated,count(r.review_id) as total_review
from hotels as h join reviews as r on h.hotel_id=r.hotel_id
                join  users as u on r.user_id=u.user_id
				group by h.hotel_name,u.traveller_type  
				having u.traveller_type ='Family'
				order by avg_rated desc,total_review desc limit 5 ;
				
--- 13.	Compare cleanliness scores given by different gender groups (M/F).
select u.user_gender, round(avg(r.score_cleanliness)) as agv_cleanliness_score
from users as u
left join reviews as r on u.user_id=r.user_id
where u.user_gender in('Male','Female')
group by u.user_gender
order by agv_cleanliness_score desc;

---14.Find hotels where foreign users (country ≠ hotel country) 
---give higher scores than local users.
with score as( select  h.hotel_name,
                       h.country as hotel_country,
                       u.country as user_country,
					case when h.country = u.country then 'local' else 'foreign' end as user_type,
					avg(score_overall) as avg_score 
					from reviews as r 
					join users as u on u.user_id=r.user_id
					join hotels as h on h.hotel_id=r.hotel_id
					group by h.hotel_name,h.country,u.country),
					pivot as(select hotel_name,
					                max(case when user_type='local' then avg_score end) as local_score,
									max(case when user_type='foreign' then avg_score end) as foreign_score
									from score
									group by hotel_name)
					select hotel_name,
					round(local_score,2) as local_score,
					round(foreign_score,2) as foreign_score,
					round(foreign_score-local_score,2) as difference_score
					from pivot
					where foreign_score> local_score
					order by  difference_score desc;

---15.Rank hotels in each city by average overall score.
with avg_city as( select  h.hotel_name,
                          h.city, 
	                      round(avg(r.score_overall),2) as avg_score_overall
	                      from hotels as h
                          left join reviews as r 
	                      on h.hotel_id=r.hotel_id 
	                      group by h.hotel_name,h.city )

select hotel_name,
       city,
	   avg_score_overall,
	   rank()over(partition by city order by avg_score_overall desc) as rank_in_the_city
	   from avg_city
	   order by city,rank_in_the_city;
					
---16.Find seasonal trends: average score_overall per hotel by month.
select distinct h.hotel_id ,h.hotel_name,
       extract(month from u.join_date) as month_name,
       round(avg(r.score_overall),2) as avg_score_overall
	   from
	   hotels as h 
	   join reviews as r on h.hotel_id=r.hotel_id
	   join users as u  on u.user_id=r.user_id
	   group by h.hotel_id,h.hotel_name,month_name 
	   order by avg_score_overall,month_name desc;
	   
---17.Check if there’s a correlation between hotel base ratings (*_base) 
---and actual user review scores.

SELECT 
    h.hotel_id,
    h.hotel_name,
    ROUND(AVG(r.score_cleanliness), 2) AS avg_cleanliness,
    ROUND(AVG(r.score_comfort), 2)     AS avg_comfort,
    ROUND(AVG(r.score_facilities), 2)  AS avg_facilities,
    ROUND(AVG(r.score_location), 2)    AS avg_location,
    ROUND(AVG(r.score_staff), 2)       AS avg_staff,
    ROUND(AVG(r.score_value_for_money), 2) AS avg_value_for_money,
    h.cleanliness_base,
    h.comfort_base,
    h.facilities_base,
    h.location_base,
    h.staff_base,
    h.value_for_money_base
FROM hotels as h
JOIN reviews as r ON h.hotel_id = r.hotel_id
GROUP BY h.hotel_id, h.hotel_name,
         h.cleanliness_base, h.comfort_base, h.facilities_base, 
         h.location_base, h.staff_base, h.value_for_money_base
ORDER BY h.hotel_id;
------
SELECT
    corr(h.cleanliness_base, r.score_cleanliness)      AS corr_cleanliness,
    corr(h.comfort_base, r.score_comfort)              AS corr_comfort,
    corr(h.facilities_base, r.score_facilities)        AS corr_facilities,
    corr(h.location_base, r.score_location)            AS corr_location,
    corr(h.staff_base, r.score_staff)                  AS corr_staff,
    corr(h.value_for_money_base, r.score_value_for_money) AS corr_value_for_money
FROM hotels h
JOIN reviews r ON h.hotel_id = r.hotel_id;


---18.Identify “hidden gems”: hotels with a low star rating 
---(<3) but high review scores (>6).

with hotel_rating as( select h.hotel_name, h.star_rating ,r.score_overall
from hotels as h 
left join  reviews as r 
on h.hotel_id=h.hotel_id
group by h.hotel_name, h.star_rating ,r.score_overall
having r.score_overall >6)
select hotel_name,star_rating,score_overall 
from hotel_rating 
where star_rating <3;
---
select h.hotel_name, h.star_rating ,r.score_overall
from hotels as h 
left join  reviews as r 
on h.hotel_id=h.hotel_id
group by h.hotel_name, h.star_rating ,r.score_overall
having r.score_overall >6 and h.star_rating<3;

---19.Analyze the age_group that gives the lowest average score overall.
select u.age_group,round(avg(r.score_overall)) as avg_score_overall
from users as u
join reviews as r on u.user_id=r.user_id
group by u.age_group 
having round(avg(r.score_overall))< 5;

---20.Find the “harshest” reviewer: the user with the
---lowest average score across their reviews.
select u.user_id,
       u.user_gender,
	   u.country,
	   u.age_group,
	   u.traveller_type,
round(avg(score_overall),2) as avg_score_overall,
count(review_id) as total_review
from users as u
join reviews as r on u.user_id=r.user_id
group by u.user_id, 
         u.user_gender,
	     u.country,
	     u.age_group,
	     u.traveller_type  
order by round(avg(score_overall),2) asc limit 1;




