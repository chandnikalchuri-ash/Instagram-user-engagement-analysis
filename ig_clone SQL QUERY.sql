-- Question 1: Check for duplicate and NULL values

/* -------------------- NULL VALUES CHECK -------------------- */

-- users
SELECT * 
FROM users
WHERE username IS NULL OR created_at IS NULL;

-- photos (note: column is created_dat)
SELECT * 
FROM photos
WHERE image_url IS NULL OR user_id IS NULL OR created_dat IS NULL;

-- comments
SELECT * 
FROM comments
WHERE comment_text IS NULL OR user_id IS NULL OR photo_id IS NULL;

-- likes
SELECT * 
FROM likes
WHERE user_id IS NULL OR photo_id IS NULL;

-- follows
SELECT * 
FROM follows
WHERE follower_id IS NULL OR followee_id IS NULL;

-- tags
SELECT * 
FROM tags
WHERE tag_name IS NULL;

-- photo_tags
SELECT * 
FROM photo_tags
WHERE photo_id IS NULL OR tag_id IS NULL;


/* -------------------- DUPLICATES CHECK -------------------- */

-- users (duplicate usernames)
SELECT username, COUNT(*) AS duplicate_count
FROM users
GROUP BY username
HAVING COUNT(*) > 1;

-- photos (duplicate URLs)
SELECT image_url, COUNT(*) AS duplicate_count
FROM photos
GROUP BY image_url
HAVING COUNT(*) > 1;

-- comments (same comment by same user on same photo)
SELECT comment_text, user_id, photo_id, COUNT(*) AS duplicate_count
FROM comments
GROUP BY comment_text, user_id, photo_id
HAVING COUNT(*) > 1;

-- likes 
SELECT user_id, photo_id, COUNT(*)
FROM likes
GROUP BY user_id, photo_id
HAVING COUNT(*) > 1;

-- follows 
SELECT follower_id, followee_id, COUNT(*)
FROM follows
GROUP BY follower_id, followee_id
HAVING COUNT(*) > 1;

-- tags (duplicate tag names)
SELECT tag_name, COUNT(*) AS duplicate_count
FROM tags
GROUP BY tag_name
HAVING COUNT(*) > 1;

-- Photo_Tages 
SELECT photo_id, tag_id, COUNT(*)
FROM photo_tags
GROUP BY photo_id, tag_id
HAVING COUNT(*) > 1;

-- Question 2: Distribution of user activity levels

WITH user_posts AS (
    SELECT user_id, COUNT(*) AS total_posts
    FROM photos
    GROUP BY user_id
),

user_likes AS (
    SELECT user_id, COUNT(*) AS total_likes
    FROM likes
    GROUP BY user_id
),

user_comments AS (
    SELECT user_id, COUNT(*) AS total_comments
    FROM comments
    GROUP BY user_id
),

user_activity AS (
    SELECT 
        u.id,
        COALESCE(p.total_posts, 0) AS posts,
        COALESCE(l.total_likes, 0) AS likes,
        COALESCE(c.total_comments, 0) AS comments,
        COALESCE(p.total_posts, 0) 
        + COALESCE(l.total_likes, 0) 
        + COALESCE(c.total_comments, 0) AS total_activity
    FROM users u
    LEFT JOIN user_posts p ON u.id = p.user_id
    LEFT JOIN user_likes l ON u.id = l.user_id
    LEFT JOIN user_comments c ON u.id = c.user_id
)

SELECT 
    CASE 
        WHEN total_activity = 0 THEN 'Inactive'
        WHEN total_activity BETWEEN 1 AND 50 THEN 'Low Activity'
        WHEN total_activity BETWEEN 51 AND 200 THEN 'Medium Activity'
        ELSE 'High Activity'
    END AS activity_level,
    COUNT(*) AS user_count
FROM user_activity
GROUP BY activity_level
ORDER BY user_count DESC;

-- Question 3: Average number of tags per post

WITH tag_count AS (
    SELECT 
        p.id,
        COUNT(pt.tag_id) AS tags_per_post
    FROM photos p
    LEFT JOIN photo_tags pt 
        ON p.id = pt.photo_id
    GROUP BY p.id
)

SELECT ROUND(AVG(tags_per_post), 2) AS avg_tags_per_post
FROM tag_count;

-- Question 4: Top users by engagement rate

WITH user_posts AS (
    SELECT user_id, COUNT(*) AS total_posts
    FROM photos
    GROUP BY user_id
),

likes_received AS (
    SELECT p.user_id, COUNT(*) AS total_likes
    FROM photos p
    JOIN likes l 
        ON p.id = l.photo_id
    GROUP BY p.user_id
),

comments_received AS (
    SELECT p.user_id, COUNT(*) AS total_comments
    FROM photos p
    JOIN comments c 
        ON p.id = c.photo_id
    GROUP BY p.user_id
),

engagement_data AS (
    SELECT 
        u.id,
        u.username,
        COALESCE(up.total_posts, 0) AS total_posts,
        COALESCE(lr.total_likes, 0) AS total_likes,
        COALESCE(cr.total_comments, 0) AS total_comments
    FROM users u
    LEFT JOIN user_posts up ON u.id = up.user_id
    LEFT JOIN likes_received lr ON u.id = lr.user_id
    LEFT JOIN comments_received cr ON u.id = cr.user_id
)

SELECT 
    id,
    username,
    total_posts,
    total_likes,
    total_comments,
    ROUND(
        (total_likes + total_comments) * 1.0 / NULLIF(total_posts, 0), 
        2
    ) AS engagement_rate,
    RANK() OVER (
        ORDER BY 
        (total_likes + total_comments) * 1.0 / NULLIF(total_posts, 0) DESC
    ) AS user_rank
FROM engagement_data
WHERE total_posts > 0;

-- Question 5: Users with highest followers and followings

WITH followers_count AS (
    SELECT 
        followee_id AS user_id,
        COUNT(*) AS total_followers
    FROM follows
    GROUP BY followee_id
),

following_count AS (
    SELECT 
        follower_id AS user_id,
        COUNT(*) AS total_following
    FROM follows
    GROUP BY follower_id
)

SELECT 
    u.id,
    u.username,
    COALESCE(fc.total_followers, 0) AS total_followers,
    COALESCE(fg.total_following, 0) AS total_following
FROM users u
LEFT JOIN followers_count fc 
    ON u.id = fc.user_id
LEFT JOIN following_count fg 
    ON u.id = fg.user_id
ORDER BY total_followers DESC, total_following DESC;

-- Question 6: Average engagement per post for each user

WITH user_posts AS (
    SELECT user_id, COUNT(*) AS total_posts
    FROM photos
    GROUP BY user_id
),

likes_received AS (
    SELECT p.user_id, COUNT(*) AS total_likes
    FROM photos p
    JOIN likes l 
        ON p.id = l.photo_id
    GROUP BY p.user_id
),

comments_received AS (
    SELECT p.user_id, COUNT(*) AS total_comments
    FROM photos p
    JOIN comments c 
        ON p.id = c.photo_id
    GROUP BY p.user_id
),

engagement_data AS (
    SELECT 
        u.id,
        u.username,
        COALESCE(up.total_posts, 0) AS total_posts,
        COALESCE(lr.total_likes, 0) AS total_likes,
        COALESCE(cr.total_comments, 0) AS total_comments
    FROM users u
    LEFT JOIN user_posts up ON u.id = up.user_id
    LEFT JOIN likes_received lr ON u.id = lr.user_id
    LEFT JOIN comments_received cr ON u.id = cr.user_id
)

SELECT 
    id,
    username,
    total_posts,
    total_likes,
    total_comments,
    ROUND(
        (total_likes + total_comments) * 1.0 / NULLIF(total_posts, 0),
        2
    ) AS avg_engagement_per_post
FROM engagement_data
WHERE total_posts > 0
ORDER BY avg_engagement_per_post DESC;

-- Question 7: Users who have never liked any post

SELECT 
    u.id,
    u.username
FROM users u
WHERE NOT EXISTS (
    SELECT 1
    FROM likes l
    WHERE l.user_id = u.id
)
ORDER BY u.id;

-- Question 8: Find most used hashtags

SELECT t.tag_name, COUNT(*) AS usage_count
FROM tags t
JOIN photo_tags pt ON t.id = pt.tag_id
GROUP BY t.tag_name
ORDER BY usage_count DESC;

-- Question 9: Engagement vs number of posts

WITH user_activity AS (
    SELECT 
        u.id,
        COUNT(p.id) AS total_posts,
        COUNT(l.photo_id) AS total_likes,
        COUNT(c.id) AS total_comments
    FROM users u
    LEFT JOIN photos p ON u.id = p.user_id
    LEFT JOIN likes l ON p.id = l.photo_id
    LEFT JOIN comments c ON p.id = c.photo_id
    GROUP BY u.id
)

SELECT 
    total_posts,
    AVG(total_likes + total_comments) AS avg_engagement
FROM user_activity
GROUP BY total_posts
ORDER BY total_posts;

-- Question 10: Total likes, comments, and tags per user

WITH likes_count AS (
    SELECT 
        p.user_id,
        COUNT(*) AS total_likes
    FROM photos p
    JOIN likes l 
        ON p.id = l.photo_id
    GROUP BY p.user_id
),

comments_count AS (
    SELECT 
        p.user_id,
        COUNT(*) AS total_comments
    FROM photos p
    JOIN comments c 
        ON p.id = c.photo_id
    GROUP BY p.user_id
),

tags_count AS (
    SELECT 
        p.user_id,
        COUNT(*) AS total_tags
    FROM photos p
    JOIN photo_tags pt 
        ON p.id = pt.photo_id
    GROUP BY p.user_id
)

SELECT 
    u.id,
    u.username,
    COALESCE(lc.total_likes, 0) AS total_likes,
    COALESCE(cc.total_comments, 0) AS total_comments,
    COALESCE(tc.total_tags, 0) AS total_photo_tags
FROM users u
LEFT JOIN likes_count lc 
    ON u.id = lc.user_id
LEFT JOIN comments_count cc 
    ON u.id = cc.user_id
LEFT JOIN tags_count tc 
    ON u.id = tc.user_id
ORDER BY total_likes DESC;

-- Question 11: Rank users based on monthly engagement

WITH monthly_posts AS (
    SELECT *
    FROM photos
    WHERE created_dat >= DATE_SUB(NOW(), INTERVAL 1 MONTH)
),

likes_count AS (
    SELECT 
        p.user_id,
        COUNT(*) AS total_likes
    FROM monthly_posts p
    JOIN likes l 
        ON p.id = l.photo_id
    GROUP BY p.user_id
),

comments_count AS (
    SELECT 
        p.user_id,
        COUNT(*) AS total_comments
    FROM monthly_posts p
    JOIN comments c 
        ON p.id = c.photo_id
    GROUP BY p.user_id
),

engagement_data AS (
    SELECT 
        u.id,
        u.username,
        COALESCE(lc.total_likes, 0) AS total_likes,
        COALESCE(cc.total_comments, 0) AS total_comments,
        COALESCE(lc.total_likes, 0) + COALESCE(cc.total_comments, 0) AS total_engagement
    FROM users u
    LEFT JOIN likes_count lc 
        ON u.id = lc.user_id
    LEFT JOIN comments_count cc 
        ON u.id = cc.user_id
)

SELECT 
    id,
    username,
    total_likes,
    total_comments,
    total_engagement,
    DENSE_RANK() OVER (ORDER BY total_engagement DESC) AS engagement_rank
FROM engagement_data
ORDER BY engagement_rank;

-- Question 12: Hashtags with highest average likes

WITH hashtag_likes AS (
    SELECT 
        t.tag_name,
        p.id AS photo_id,
        COUNT(l.photo_id) AS likes_per_post
    FROM tags t
    JOIN photo_tags pt 
        ON t.id = pt.tag_id
    JOIN photos p 
        ON pt.photo_id = p.id
    LEFT JOIN likes l 
        ON p.id = l.photo_id
    GROUP BY t.tag_name, p.id
),

hashtag_avg AS (
    SELECT 
        tag_name,
        ROUND(AVG(likes_per_post), 2) AS avg_likes
    FROM hashtag_likes
    GROUP BY tag_name
)

SELECT *
FROM hashtag_avg
ORDER BY avg_likes DESC;

-- Question 13: Users who followed back

SELECT 
    u1.id AS user_id,
    u1.username AS user_name,
    u2.id AS followed_user_id,
    u2.username AS followed_user_name,
    f1.created_at AS first_follow_time,
    f2.created_at AS follow_back_time
FROM follows f1
JOIN follows f2 
    ON f1.follower_id = f2.followee_id
   AND f1.followee_id = f2.follower_id
JOIN users u1 
    ON f1.follower_id = u1.id
JOIN users u2 
    ON f1.followee_id = u2.id
WHERE f1.created_at < f2.created_at
ORDER BY follow_back_time;

/*                                                  SUBJECTIVE QUESTIONS                                           */

/* 1.	Based on user engagement and activity levels, which users would you consider the most loyal or valuable? How would you reward or incentivize these users? */

WITH user_posts AS (
    SELECT user_id, COUNT(*) AS total_posts
    FROM photos
    GROUP BY user_id
),

likes_received AS (
    SELECT p.user_id, COUNT(*) AS total_likes
    FROM photos p
    JOIN likes l 
        ON p.id = l.photo_id
    GROUP BY p.user_id
),

comments_received AS (
    SELECT p.user_id, COUNT(*) AS total_comments
    FROM photos p
    JOIN comments c 
        ON p.id = c.photo_id
    GROUP BY p.user_id
),

engagement_data AS (
    SELECT 
        u.id,
        u.username,
        COALESCE(up.total_posts, 0) AS total_posts,
        COALESCE(lr.total_likes, 0) AS total_likes,
        COALESCE(cr.total_comments, 0) AS total_comments,
        (COALESCE(lr.total_likes, 0) + COALESCE(cr.total_comments, 0)) AS total_engagement
    FROM users u
    LEFT JOIN user_posts up ON u.id = up.user_id
    LEFT JOIN likes_received lr ON u.id = lr.user_id
    LEFT JOIN comments_received cr ON u.id = cr.user_id
)
SELECT 
    id,
    username,
    total_posts,
    total_likes,
    total_comments,
    total_engagement
FROM engagement_data
ORDER BY total_engagement DESC
LIMIT 10;

-- 2.    Inactive users identify karna (no posts, no likes, no comments)

WITH user_posts AS (
    SELECT user_id, COUNT(*) AS total_posts
    FROM photos
    GROUP BY user_id
),

user_likes AS (
    SELECT user_id, COUNT(*) AS total_likes
    FROM likes
    GROUP BY user_id
),

user_comments AS (
    SELECT user_id, COUNT(*) AS total_comments
    FROM comments
    GROUP BY user_id
),

user_activity AS (
    SELECT 
        u.id,
        u.username,
        COALESCE(p.total_posts, 0) AS posts,
        COALESCE(l.total_likes, 0) AS likes,
        COALESCE(c.total_comments, 0) AS comments,
        (COALESCE(p.total_posts,0) 
        + COALESCE(l.total_likes,0) 
        + COALESCE(c.total_comments,0)) AS total_activity
    FROM users u
    LEFT JOIN user_posts p ON u.id = p.user_id
    LEFT JOIN user_likes l ON u.id = l.user_id
    LEFT JOIN user_comments c ON u.id = c.user_id
)

SELECT *
FROM user_activity
WHERE total_activity = 0;

/*       3.   Which hashtags or content topics have the highest engagement
rates ? How can this information guide content strategy and ad
campaigns?      */

WITH hashtag_engagement AS (
    SELECT 
        t.tag_name,
        COUNT(DISTINCT pt.photo_id) AS total_posts,
        COUNT(l.photo_id) AS total_likes,
        COUNT(c.photo_id) AS total_comments
    FROM tags t
    JOIN photo_tags pt ON t.id = pt.tag_id
    LEFT JOIN likes l ON pt.photo_id = l.photo_id
    LEFT JOIN comments c ON pt.photo_id = c.photo_id
    GROUP BY t.tag_name
)

SELECT 
    tag_name,
    total_posts,
    total_likes,
    total_comments,
    ROUND(
        (total_likes + total_comments) * 1.0 / NULLIF(total_posts, 0), 
        2
    ) AS engagement_rate
FROM hashtag_engagement
ORDER BY engagement_rate DESC;

/*     4.     Are there any patterns or trends in user engagement based on
demographics (age, location, gender) or posting times? How can
these insights inform targeted marketing campaigns?          */

SELECT 
    COUNT(*) AS total_posts,
    ROUND(AVG(likes_count),2) AS avg_likes,
    ROUND(AVG(comments_count),2) AS avg_comments
FROM (
    SELECT 
        p.id,
        COUNT(DISTINCT l.photo_id) AS likes_count,
        COUNT(DISTINCT c.photo_id) AS comments_count
    FROM photos p
    LEFT JOIN likes l ON p.id = l.photo_id
    LEFT JOIN comments c ON p.id = c.photo_id
    GROUP BY p.id
) AS post_engagement;

/*     5. Based on follower counts and engagement rates, which users would be ideal candidates for influencer marketing campaigns?
          How would you approach and collaborate with these influencers?     */
          
WITH followers_count AS (
    SELECT 
        followee_id AS user_id,
        COUNT(*) AS total_followers
    FROM follows
    GROUP BY followee_id
),

engagement AS (
    SELECT 
        p.user_id,
        COUNT(l.photo_id) AS total_likes,
        COUNT(c.photo_id) AS total_comments,
        COUNT(DISTINCT p.id) AS total_posts
    FROM photos p
    LEFT JOIN likes l ON p.id = l.photo_id
    LEFT JOIN comments c ON p.id = c.photo_id
    GROUP BY p.user_id
)

SELECT 
    u.id,
    u.username,
    COALESCE(f.total_followers, 0) AS followers,
    COALESCE(e.total_posts, 0) AS posts,
    COALESCE(e.total_likes, 0) AS likes,
    COALESCE(e.total_comments, 0) AS comments,
    ROUND(
        (COALESCE(e.total_likes,0) + COALESCE(e.total_comments,0)) 
        / NULLIF(e.total_posts,0), 
        2
    ) AS engagement_rate
FROM users u
LEFT JOIN followers_count f ON u.id = f.user_id
LEFT JOIN engagement e ON u.id = e.user_id
WHERE e.total_posts > 0
ORDER BY followers DESC, engagement_rate DESC;       

/*      6.   Based on user behavior and engagement data, how would you
segment the user base for targeted marketing campaigns or
personalized recommendations?      */

WITH user_posts AS (
    SELECT user_id, COUNT(*) AS total_posts
    FROM photos
    GROUP BY user_id
),

user_likes AS (
    SELECT user_id, COUNT(*) AS total_likes
    FROM likes
    GROUP BY user_id
),

user_comments AS (
    SELECT user_id, COUNT(*) AS total_comments
    FROM comments
    GROUP BY user_id
),

user_activity AS (
    SELECT 
        u.id,
        u.username,
        COALESCE(p.total_posts, 0) AS total_posts,
        COALESCE(l.total_likes, 0) AS total_likes,
        COALESCE(c.total_comments, 0) AS total_comments
    FROM users u
    LEFT JOIN user_posts p ON u.id = p.user_id
    LEFT JOIN user_likes l ON u.id = l.user_id
    LEFT JOIN user_comments c ON u.id = c.user_id
),

segmented_users AS (
    SELECT *,
        (total_posts + total_likes + total_comments) AS total_activity,
        CASE 
            WHEN (total_posts + total_likes + total_comments) >= 200 THEN 'High Value Users'
            WHEN (total_posts + total_likes + total_comments) BETWEEN 100 AND 199 THEN 'Moderate Users'
            WHEN (total_posts + total_likes + total_comments) BETWEEN 1 AND 99 THEN 'Low Activity Users'
            ELSE 'Inactive Users'
        END AS user_segment
    FROM user_activity
)

SELECT 
    user_segment,
    COUNT(*) AS total_users
FROM segmented_users
GROUP BY user_segment
ORDER BY total_users DESC;

/*    7.    If data on ad campaigns (impressions, clicks, conversions) is available, 
how would you measure their effectiveness and optimize future campaigns?    */

create table ad_campaigns (
      campaign_id INT,
      campaign_name varchar(50),
      impressions int,
      clicks int,
      conversions int
);
insert into ad_campaigns values
(1, 'Campaign A', 10000, 500, 50),
(2, 'Campaign B', 15000, 700, 80),
(3, 'Campaign C', 8000, 300, 40);
 
SELECT 
    campaign_id,
    campaign_name,
    impressions,
    clicks,
    conversions,

    ROUND(clicks * 100.0 / NULLIF(impressions, 0), 2) AS ctr_percentage,

    ROUND(conversions * 100.0 / NULLIF(clicks, 0), 2) AS conversion_rate,

    ROUND(conversions * 100.0 / NULLIF(impressions, 0), 2) AS overall_performance
FROM ad_campaigns
ORDER BY overall_performance DESC;

/*    8.   How can you use user activity data to identify potential brand ambassadors or
 advocates who could help promote Instagram's initiatives or events?       */

WITH user_posts AS (
    SELECT user_id, COUNT(*) AS total_posts
    FROM photos
    GROUP BY user_id
),

user_likes AS (
    SELECT user_id, COUNT(*) AS total_likes
    FROM likes
    GROUP BY user_id
),

user_comments AS (
    SELECT user_id, COUNT(*) AS total_comments
    FROM comments
    GROUP BY user_id
),

user_engagement AS (
    SELECT 
        u.id,
        u.username,
        COALESCE(p.total_posts, 0) AS total_posts,
        COALESCE(l.total_likes, 0) AS total_likes,
        COALESCE(c.total_comments, 0) AS total_comments,
        (COALESCE(p.total_posts, 0) + 
         COALESCE(l.total_likes, 0) + 
         COALESCE(c.total_comments, 0)) AS total_activity
    FROM users u
    LEFT JOIN user_posts p ON u.id = p.user_id
    LEFT JOIN user_likes l ON u.id = l.user_id
    LEFT JOIN user_comments c ON u.id = c.user_id
)

SELECT 
    id,
    username,
    total_posts,
    total_likes,
    total_comments,
    total_activity,
    CASE 
        WHEN total_activity >= 500 THEN 'Brand Ambassador'
        WHEN total_activity BETWEEN 200 AND 499 THEN 'Potential Advocate'
        ELSE 'Regular User'
    END AS user_type
FROM user_engagement
ORDER BY total_activity DESC;

/*          9.  How would you approach this problem, 
        if the objective and subjective questions weren't given?        */

SELECT 
    u.id,
    u.username,
    COUNT(DISTINCT p.id) AS total_posts,
    COUNT(DISTINCT l.photo_id) AS total_likes,
    COUNT(DISTINCT c.photo_id) AS total_comments
FROM users u
LEFT JOIN photos p ON u.id = p.user_id
LEFT JOIN likes l ON p.id = l.photo_id
LEFT JOIN comments c ON p.id = c.photo_id
GROUP BY u.id, u.username
ORDER BY total_posts DESC;

/*           10.   Assuming there's a "User_Interactions" table tracking user engagements, 
                     how can you update the "Engagement_Type" column to 
               change all instances of "Like" to "Heart" to align with Instagram's terminology?        */
               
UPDATE User_Interactions
SET Engagement_Type = 'Heart'
WHERE Engagement_Type = 'Like';