-- Fetch all the paintings which are not displayed on any museums?
select * from work
where museum_id is null;

-- Are there museuems without any paintings?
select * from museum m
where not exists (select 1 from work w where w.museum_id=m.museum_id); 

-- How many paintings have an asking price of more than their regular price?
select * from product_size
where sale_price>regular_price; -- no paintings are there

-- Identify the paintings whose asking price is less than 50% of its regular price?
select * from product_size 
where sale_price < (regular_price*0.5);

-- Identify the museums which are open on both Sunday and Monday.
select * from museum_hours
where day in ('sunday', 'monday');

-- Which canva size costs the most?
select max(sale_price) from product_size;

-- Which canva size costs the most?
select cs.label as canva, ps.sale_price 
from (select *, rank() over(order by sale_price desc) rnk
		from product_size) ps
join canvas_size cs on cs.size_id=ps.size_id
where ps.rnk=1;

-- Identify the museums with invalid city information in the given dataset?
select * from museum;

SELECT * FROM museum 
WHERE city REGEXP '[0-9]';

-- Museum_Hours table has 1 invalid entry. Identify it and remove it.
select * from museum_hours;




-- Fetch the top 10 most famous painting subject
select * from subject;
select * from(
				select s.subject, count(1) as no_of_paintings, rank() over(order by count(1) desc) as rnk
                from work w
                join subject s on w.work_id = s.work_id
                group by s.subject ) x
where rnk<=10;

-- How many museums are open every single day?
select count(1) from ( select museum_id, count(1) from museum_hours
						group by museum_id having count(1) = 7)x;

/* Which are the top 5 most popular museum?(Popularity is defined based on most no of paintings
 in a museum)*/
select m.name as museum, m.city, m.country, x.no_of_paintings from
(select m.museum_id, count(1) as no_of_paintings, rank() over (order by count(1) desc) as rnk
from work w join museum m on m.museum_id=w.museum_id
group by m.museum_id)x
join museum m on m.museum_id=x.museum_id
where x.rnk<=5;

/* Who are the top 5 most popular artist?(Popularity is defined based on most no
of paintings done by an artist)*/
select a.full_name, a.nationality, x.no_of_paintings from(
select a.artist_id, count(1) as no_of_paintings, rank() over(order by count(1) desc) as rnk
from artist a
join work w on a.artist_id = w.artist_id
group by a.artist_id)x 
join artist a on a.artist_id = x.artist_id
where x.rnk<=5;

/*Display the 3 least popular canva sizes*/
select label, rnk, no_of_paintings from 
(select cs.size_id, cs.label, count(1) as no_of_paintings,
		dense_rank() over(order by count(1)) as rnk from product_size ps
        join canvas_size cs on ps.size_id=cs.size_id
        group by cs.size_id, cs.label)x
where x.rnk<=3;

/*Which museum is open for the longest during a day. 
Dispay museum name, state and hours open and which day?*/
select m.name as museum_name, m.city as city, mh.day,
TIMEDIFF(mh.close, mh.open) as duration_open
from museum m
join museum_hours mh on m.museum_id=mh.museum_id
order by duration_open desc
limit 1;

/*Which museum has the most no of most popular painting style?*/
with pop_style as 
				(select style, rank() over(order by count(1) desc) as rnk
                from work 
                group by style), 
	cte as 
		  (select w.museum_id, w.name as museum_name, ps.style, count(1) as no_of_paintings,
          rank() over(order by count(1) desc)rnk
          from work w 
          join museum m on m.museum_id=w.museum_id
          join pop_style ps on ps.style=w.style
          where w.museum_id is not null and ps.rnk=1
          group by w.museum_id, w.name, ps.style)
  select museum_name, style, no_of_paintings
  from cte
  where rnk=1;
  
/* Identify the artists whose paintings are displayed in multiple countries*/
with cte as(
		select distinct a.full_name as artist_name, w.name as painting_name, 
        m.name as museum_name, m.country  
		from work w 
		join artist a on a.artist_id=w.artist_id
		join museum m on m.museum_id=w.museum_id)
select artist_name, painting_name, count(1) as no_of_countries
from cte 
group by artist_name, painting_name
having count(1)>1
order by no_of_countries desc;

/*Display the country and the city with most no of museums.
 Output 2 seperate columns to mention the city and country. 
 If there are multiple value, seperate them with comma.*/
 with cte_country as(
					 select country, count(1), rank() over(order by count(1) desc) as rnk
					 from museum group by country),
       cte_city as (
					select city, count(1), rank() over(order by count(1) desc) as rnk
					from museum group by city)
select string_agg (country.country,','),
string_agg(city.city,',')
from cte_country country
cross join cte_city city
where country.rnk=1
and city.rnk = 1;                   

/*





















