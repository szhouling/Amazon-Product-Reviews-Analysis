-- 1. What is the average discount percentage for products within the top 10% highest-rated
-- products?

SELECT ROUND(AVG(discount_percentage), 2) AS average_discount_percentage
FROM (
    SELECT pp.product_id, pp.discount_percentage
    FROM Productprice pp
    INNER JOIN (
        SELECT product_id, AVG(rating_score) AS avg_rating,
               RANK() OVER (ORDER BY AVG(rating_score) DESC) AS rating_rank,
               COUNT(*) OVER () AS total_products
        FROM Rating
        GROUP BY product_id
    ) AS AvgRatings
    ON AvgRatings.product_id = pp.product_id
    WHERE AvgRatings.rating_rank <= AvgRatings.total_products * 0.1
) AS TopDiscounts;

-- Insights: A high average discount suggests that customers may be quite price-sensitive, even for the highest-rated products. 
-- It implies that discounts are a strong driver of sales for these products. The need to offer such substantial discounts on 
-- top-rated products could indicate a highly competitive market where price promotions are necessary to maintain a competitive edge.

-- 2. Which users have the highest average rating score across all their reviews, and how does
-- it compare to the overall average?
SELECT 
    u.user_id, 
    u.user_name, 
    UserAvg.avg_rating AS user_average_rating, 
    OverallAvg.overall_average_rating
FROM (
    SELECT 
        user_id, 
        AVG(rating_score) AS avg_rating
    FROM Rating
    GROUP BY user_id
) AS UserAvg
INNER JOIN User u ON UserAvg.user_id = u.user_id
CROSS JOIN (
    SELECT 
        AVG(rating_score) AS overall_average_rating
    FROM Rating
) AS OverallAvg
WHERE UserAvg.avg_rating > OverallAvg.overall_average_rating
ORDER BY UserAvg.avg_rating DESC;

-- Insights:Influential Reviewers: The users listed with high average ratings significantly above the overall average could be influential reviewers. 
-- Their opinions may carry more weight with other customers due to the high ratings they give.
-- Marketing Potential: These users could be leveraged in marketing campaigns as testimonials or as part of a user advocacy program. 
-- Their consistently high ratings can be a persuasive tool for other potential customers.


-- 3. Can we identify any correlation between the length of a review title and the associated
-- product rating?
SELECT 
    r.review_id, 
    CHAR_LENGTH(r.review_title) AS review_title_length, 
    ra.rating_score
FROM Review r
INNER JOIN Rating ra ON r.product_id = ra.product_id
order by ra.rating_score;

-- Insights: Analyzing the length of review titles, along with the content of the reviews themselves, can provide businesses 
-- with a nuanced understanding of customer sentiment, preferences, and priorities.

-- 4. For each product category, identify the product with the highest average rating
-- and compare it to the category's overall average rating.
WITH CategoryAverageRatings AS (
    SELECT 
        p.category,
        AVG(ra.rating_score) AS category_avg_rating
    FROM Rating ra
    INNER JOIN Product p ON ra.product_id = p.product_id
    GROUP BY p.category
),
ProductAverageRatings AS (
    SELECT 
        p.product_id,
        p.category,
        p.product_name,
        AVG(ra.rating_score) AS product_avg_rating
    FROM Rating ra
    INNER JOIN Product p ON ra.product_id = p.product_id
    GROUP BY p.product_id, p.category, p.product_name
),
BestRatedProductsInCategory AS (
    SELECT 
        par.category,
        par.product_id,
        par.product_name,
        par.product_avg_rating,
        RANK() OVER (PARTITION BY par.category ORDER BY par.product_avg_rating DESC) as rank_in_category
    FROM ProductAverageRatings par
)
SELECT 
    b.category,
    b.product_id,
    b.product_name,
    b.product_avg_rating,
    c.category_avg_rating
FROM BestRatedProductsInCategory b
INNER JOIN CategoryAverageRatings c ON b.category = c.category
WHERE b.rank_in_category = 1;

-- Insights: By identifying which products have the highest average ratings, the business determine which products are performing well and potentially invest more in marketing these products. 
-- It can also help in decision-making about which products may need improvements if their ratings are lower than the category average.

-- 5. Which product has the most significant discrepancy between its actual price and its
-- average discounted price?
SELECT 
    p.product_id,
    p.product_name,
    p.category,
    pp.actual_price,
    AVG(pp.discounted_price) AS average_discounted_price,
    (pp.actual_price - AVG(pp.discounted_price)) AS price_discrepancy
FROM Productprice pp
INNER JOIN Product p ON pp.product_id = p.product_id
GROUP BY pp.product_id, pp.actual_price
ORDER BY price_discrepancy DESC
LIMIT 5;

-- Insights: Analyzing the gap between actual and discounted prices can shed light on the effectiveness of discount strategies. 
-- A large discrepancy may attract more customers but could also lead to a perception of overpricing or diminish the perceived value of the product.

-- 6. Can we identify any prolific reviewers whose review count significantly exceeds the average, 
-- and what is the ratio of their activity to the average reviewer?
WITH UserReviewCounts AS (
    SELECT 
        user_id,
        COUNT(*) AS number_of_reviews,
        AVG(COUNT(*)) OVER () AS avg_number_of_reviews
    FROM Review
    GROUP BY user_id
),
ProlificReviewers AS (
    SELECT 
        user_id,
        number_of_reviews,
        avg_number_of_reviews,
        (number_of_reviews / avg_number_of_reviews) AS activity_ratio
    FROM UserReviewCounts
)
SELECT *
FROM ProlificReviewers
WHERE number_of_reviews > avg_number_of_reviews
ORDER BY activity_ratio DESC;

-- Insights: Businesses might use this information to develop a community of reviewers, providing them with early access to products or exclusive offers to encourage high-quality, detailed reviews.

-- 7. For each category, how does the average product rating compare before and after
-- applying a discount?
SELECT 
    p.category,
    AVG(CASE WHEN pp.discount_percentage > 0 THEN ra.rating_score ELSE NULL END) AS average_rating_after_discount,
    AVG(CASE WHEN pp.discount_percentage = 0 THEN ra.rating_score ELSE NULL END) AS average_rating_before_discount
FROM Product p
INNER JOIN Productprice pp ON p.product_id = pp.product_id
INNER JOIN Rating ra ON p.product_id = ra.product_id
GROUP BY p.category;

-- Insights: Understanding which categories benefit from discounts in terms of improved ratings can help in allocating marketing resources and 
-- discounts more effectively to categories that are more responsive to price changes.

-- 8. Which product categories have the most ratings, and what is the average rating for these categories
WITH CategoryReviewCounts AS (
    SELECT 
        p.category,
        COUNT(r.rating_id) AS rating_count,
        AVG(r.rating_score) AS average_rating
    FROM rating r
    JOIN Product p ON r.product_id = p.product_id
    GROUP BY p.category
)
SELECT 
    category,
    rating_count,
    average_rating
FROM CategoryReviewCounts
ORDER BY rating_count DESC
LIMIT 5;

-- Insights: Categories with both a high number of ratings and a high average rating are likely performing well, which could be highlighted in marketing campaigns. 







