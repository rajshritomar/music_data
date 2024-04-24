
--Q1 who is the senior most employee based on job title?
SELECT TOP 1 * FROM dbo.employee
ORDER BY levels desc;

--Q2 which country have most invoice?
SELECT * FROM dbo.invoice
SELECT count(*) as max_invoice ,billing_country from invoice
group by billing_country
order by max_invoice desc


--Q3 What are top 3 values of total invoice?
SELECT * FROM dbo.invoice
SELECT TOP 3 TOTAL FROM invoice
order by total desc


--Q4 which city has the best customers? we would like to throw a promontional music festival in the city we made the most money. write a 
--query that returns one city that has the highest sum of invoice totals returns both the city name and sum of all invoice totals?
select * from invoice
select sum(total) as tot_sum , billing_city from invoice
group by billing_city
order by tot_sum desc

--Q5 who is the best customer? the customer who has spent the most money will be declared ther best customer. write a query that return the person
-- who has spent the most money?
select * from dbo.customer
select TOP 1 sum(b.total) as max_spent , concat(a.first_name , '', a.last_name) as cust , a.customer_id from dbo.customer as a
inner join dbo.invoice as b on a.customer_id = b.customer_id
group by concat(first_name , '', last_name) , a.customer_id
order by max_spent desc

--Q6 Write query to return the email , first name , last name and genre of all rock music listeners. Return your list ordered alphabetically
--by email starting with A?
select * from dbo.genre
select * from dbo.customer
select * from dbo.invoice_line

select distinct email , first_name , last_name from customer as a
inner join invoice as b on a.customer_id = b.customer_id
inner join invoice_line as c on b.invoice_id = c.invoice_id
where track_id in(
                  select track_id from track as d
				  inner join genre as e on d.genre_id = e.genre_id
				  where e.name LIKE 'Rock'
				  )
order by email;

--Q7 let's invite the artists who have written the most rock music in our dataset. write a query that returns the artist name and total track
--count of the top 10 rock bands?
select * from dbo.artist
select * from dbo.track

SELECT TOP 10
    c.artist_id,
    c.name,
    COUNT(c.artist_id) as no_songs
FROM
    track AS a
INNER JOIN
    album AS b ON b.album_id = a.album_id
INNER JOIN
    artist AS c ON c.artist_id = b.artist_id
INNER JOIN
    genre AS d ON d.genre_id = a.genre_id
WHERE
    d.name LIKE 'Rock'
GROUP BY
    c.artist_id, c.name  
ORDER BY
    COUNT(c.artist_id) DESC;  



--Q8 Return all the track names that have a song length longer than the average song length. Return the name and miliseconds for each track.
--order by the songs length with the longest songs listed first?
select * from dbo.track
select name , milliseconds from track
where milliseconds > ( select AVG(milliseconds) as avg_track from track )
order by milliseconds desc;


--Q 9 Find how much amount spent by each customer on artists? write a query to return customer name , artist name and total spent?
 
WITH best_selling_artist AS (
    SELECT TOP 1
        artist.artist_id AS artist_id,
        artist.name AS artist_name,
        SUM(invoice_line.unit_price * invoice_line.quantity) AS total_sales
    FROM
        invoice_line
    JOIN
        track ON track.track_id = invoice_line.track_id
    JOIN
        album ON album.album_id = track.album_id
    JOIN
        artist ON artist.artist_id = album.artist_id
    GROUP BY
        artist_id
    ORDER BY
        3 DESC
),
customer_sales AS (
    SELECT
        c.customer_id,
        c.first_name,
        c.last_name,
        bsa.artist_name,
        SUM(il.unit_price * il.quantity) AS amount_spent
    FROM
        invoice i
    JOIN
        customer c ON c.customer_id = i.customer_id
    JOIN
        invoice_line il ON il.invoice_id = i.invoice_id
    JOIN
        track t ON t.track_id = il.track_id
    JOIN
        album alb ON alb.album_id = t.album_id
    JOIN
        best_selling_artist bsa ON bsa.artist_id = alb.artist_id
    GROUP BY
        c.customer_id,
        c.first_name,
        c.last_name,
        bsa.artist_name
)
SELECT
    customer_id,
    first_name,
    last_name,
    artist_name,
    amount_spent
FROM
    customer_sales
ORDER BY
    amount_spent DESC



/* Q2: We want to find out the most popular music Genre for each country. We determine the most popular genre as the genre 
with the highest amount of purchases. Write a query that returns each country along with the top Genre. For countries where 
the maximum number of purchases is shared return all Genres. */
WITH popular_genre AS 
(
    SELECT 
        COUNT(invoice_line.quantity) AS purchases, 
        customer.country, 
        genre.name, 
        genre.genre_id, 
        ROW_NUMBER() OVER(PARTITION BY customer.country ORDER BY COUNT(invoice_line.quantity) DESC) AS RowNo 
    FROM 
        invoice_line 
    JOIN 
        invoice ON invoice.invoice_id = invoice_line.invoice_id
    JOIN 
        customer ON customer.customer_id = invoice.customer_id
    JOIN 
        track ON track.track_id = invoice_line.track_id
    JOIN 
        genre ON genre.genre_id = track.genre_id
    GROUP BY 
        customer.country, 
        genre.name, 
        genre.genre_id
)
SELECT 
    * 
FROM 
    popular_genre 
WHERE 
    RowNo <= 1;



/* Q3: Write a query that determines the customer that has spent the most on music for each country. 
Write a query that returns the country along with the top customer and how much they spent. 
For countries where the top amount spent is shared, provide all customers who spent this amount. */

WITH Customter_with_country AS (
    SELECT 
        customer.customer_id,
        first_name,
        last_name,
        billing_country,
        SUM(total) AS total_spending,
        ROW_NUMBER() OVER(PARTITION BY billing_country ORDER BY SUM(total) DESC) AS RowNo 
    FROM 
        invoice
    JOIN 
        customer ON customer.customer_id = invoice.customer_id
    GROUP BY 
        customer.customer_id,
        first_name,
        last_name,
        billing_country
)
SELECT 
    * 
FROM 
    Customter_with_country 
WHERE 
    RowNo <= 1 AND billing_country IS NOT NULL; 
