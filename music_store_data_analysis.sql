-- Who is the senior most employee based on the job title?
SELECT * FROM employee
ORDER BY levels DESC
LIMIT 1;

-- Which country has the most invoices?
SELECT COUNT(*) as c, billing_country
FROM invoice
GROUP BY billing_country
ORDER BY C DESC;

-- What are the top three values of total invoice?
SELECT total 
FROM invoice
ORDER BY total DESC
LIMIT 3;

/* Which city has the best customers? We would like to throw a promotional Music Festival in the city we made the most money. 
Write a query that returns one city that has the highest sum of invoice totals. 
Return both the city name & sum of all invoice totals */

SELECT billing_city, SUM(total) AS invoice_total
FROM invoice
GROUP BY billing_city
ORDER BY invoice_total DESC
LIMIT 1;

/* Who is the best customer? The customer who has spent the most money will be declared the best customer. 
Write a query that returns the person who has spent the most money.*/

SELECT c.customer_id, c.first_name, c.last_name, SUM(i.total) AS total_spending
FROM music_store_data.customer c
JOIN music_store_data.invoice i
ON c.customer_id = i.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY total_spending DESC 
LIMIT 1;

 /* Write query to return the email, first name, last name, & Genre of all Rock Music listeners. 
Return your list ordered alphabetically by email starting with A. */

SELECT DISTINCT c.email, c.first_name, c.last_name 
FROM music_store_data.customer c
JOIN music_store_data.invoice i ON c.customer_id = i.customer_id
JOIN music_store_data.invoice_line il ON i.invoice_id = il.invoice_id
WHERE track_id IN(
		SELECT track_id FROM track t
        JOIN music_store_data.genre g ON t.genre_id=g.genre_id
        WHERE g.name LIKE 'Rock'
)
ORDER BY email;

/* Let's invite the artists who have written the most rock music in our dataset. 
Write a query that returns the Artist name and total track count of the top 10 rock bands. */

SELECT ar.artist_id, ar.name, COUNT(ar.artist_id) AS number_of_songs
FROM music_store_data.track t
JOIN music_store_data.album2 al2 ON al2.album_id = t.album_id
JOIN music_store_data.artist ar ON ar.artist_id = al2.artist_id
JOIN music_store_data.genre g ON g.genre_id = t.genre_id
WHERE g.name LIKE 'Rock'
GROUP BY ar.artist_id, ar.name
ORDER BY number_of_songs DESC
LIMIT 10;


/* Return all the track names that have a song length longer than the average song length. 
Return the Name and Milliseconds for each track. Order by the song length with the longest songs listed first. */

SELECT name, milliseconds
FROM track
WHERE milliseconds > (
		SELECT AVG(milliseconds) AS avg_track_length
        FROM track)
ORDER BY milliseconds DESC;


-- Find how much amount spent by each customer on artists? Write a query to return customer name, artist name and total spent */

/* Steps to Solve: First, find which artist has earned the most according to the InvoiceLines. Now use this artist to find 
which customer spent the most on this artist. For this query, you will need to use the Invoice, InvoiceLine, Track, Customer, 
Album, and Artist tables. Note, this one is tricky because the Total spent in the Invoice table might not be on a single product, 
so you need to use the InvoiceLine table to find out how many of each product was purchased, and then multiply this by the price
for each artist. */

WITH best_selling_artist AS (
	SELECT artist.artist_id AS artist_id, artist.name AS artist_name, SUM(invoice_line.unit_price*invoice_line.quantity) AS total_sales
	FROM music_store_data.invoice_line
	JOIN music_store_data.track ON track.track_id = invoice_line.track_id
	JOIN music_store_data.album2 ON album2.album_id = track.album_id
	JOIN music_store_data.artist ON artist.artist_id = album2.artist_id
	GROUP BY artist_id,artist_name
	ORDER BY total_sales DESC
	LIMIT 1
)
SELECT c.customer_id, c.first_name, c.last_name, bsa.artist_name, SUM(il.unit_price*il.quantity) AS amount_spent
FROM music_store_data.invoice i
JOIN music_store_data.customer c ON c.customer_id = i.customer_id
JOIN music_store_data.invoice_line il ON il.invoice_id = i.invoice_id
JOIN music_store_data.track t ON t.track_id = il.track_id
JOIN music_store_data.album2 alb ON alb.album_id = t.album_id
JOIN best_selling_artist bsa ON bsa.artist_id = alb.artist_id
GROUP BY customer_id, first_name,last_name, artist_name
ORDER BY amount_spent DESC;


/* Q2: We want to find out the most popular music Genre for each country. We determine the most popular genre as the genre 
with the highest amount of purchases. Write a query that returns each country along with the top Genre. For countries where 
the maximum number of purchases is shared return all Genres. */

/* Steps to Solve:  There are two parts in question- first most popular music genre and second need data at country level. */

WITH popular_genre AS 
(
    SELECT COUNT(invoice_line.quantity) AS purchases, customer.country, genre.name, genre.genre_id, 
	ROW_NUMBER() OVER(PARTITION BY customer.country ORDER BY COUNT(invoice_line.quantity) DESC) AS RowNo 
    FROM music_store_data.invoice_line 
	JOIN music_store_data.invoice ON invoice.invoice_id = invoice_line.invoice_id
	JOIN music_store_data.customer ON customer.customer_id = invoice.customer_id
	JOIN music_store_data.track ON track.track_id = invoice_line.track_id
	JOIN music_store_data.genre ON genre.genre_id = track.genre_id
	GROUP BY  customer.country, genre.name, genre.genre_id
	ORDER BY customer.country ASC , purchases DESC
)
SELECT * FROM popular_genre WHERE RowNo <= 1


/* Q3: Write a query that determines the customer that has spent the most on music for each country. 
Write a query that returns the country along with the top customer and how much they spent. 
For countries where the top amount spent is shared, provide all customers who spent this amount. */

-- Steps to Solve:  Similar to the above question. There are two parts in question- 
-- first find the most spent on music for each country and second filter the data for respective customers. 


WITH RECURSIVE 
	customter_with_country AS (
		SELECT customer.customer_id,first_name,last_name,billing_country,SUM(total) AS total_spending
		FROM music_store_data.invoice
		JOIN music_store_data.customer ON customer.customer_id = invoice.customer_id
		GROUP BY customer.customer_id,first_name,last_name,billing_country
		ORDER BY  first_name,last_name DESC),

	country_max_spending AS(
		SELECT billing_country,MAX(total_spending) AS max_spending
		FROM customter_with_country
		GROUP BY billing_country)

SELECT cc.billing_country, cc.total_spending, cc.first_name, cc.last_name, cc.customer_id
FROM customter_with_country cc
JOIN country_max_spending ms
ON cc.billing_country = ms.billing_country
WHERE cc.total_spending = ms.max_spending
ORDER BY 1;
