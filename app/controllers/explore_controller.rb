class ExploreController < ApplicationController
  def index
    # Recommend users: most posts, exclude current user, exclude already-followed
    user_ids_to_exclude = []
    if user_signed_in?
      user_ids_to_exclude = [current_user.id] + current_user.following.pluck(:id)
    end
    @users = User.left_joins(:posts)
                 .group('users.id')
                 .order(Arel.sql('COUNT(posts.id) DESC'), Arel.sql('MAX(users.created_at) DESC'))
                 .limit(12)
    @users = @users.where.not(id: user_ids_to_exclude) if user_ids_to_exclude.any?

    # Recommend communities: most followers, then posts
    community_ids_to_exclude = []
    if user_signed_in?
      community_ids_to_exclude = current_user.followed_communities.pluck(:id)
    end
    @communities = Community.order(followers_count: :desc, posts_count: :desc).limit(12)
    @communities = @communities.where.not(id: community_ids_to_exclude) if community_ids_to_exclude.any?
  end
end

