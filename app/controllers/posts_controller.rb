class PostsController < ApplicationController
  before_action :set_post, only: %i[ show edit update destroy ]

  # GET /posts or /posts.json
  def index
    @posts = Post.all
  end

  def all_posts
    @posts = Post.where(user_id: current_user.id)
  end

  # GET /posts/1 or /posts/1.json
  def show
    @posts = Post.all
  end

  def activities
    @postsActivitiesAba = Post.where(category: "Activities", location:"ABA")
    @postsActivitiesHome = Post.where(category: "Activities", location:"Home")
  end
  def crafts
    @postsCraftsAba = Post.where(category: "Crafts", location:"ABA")
    @postsCraftsHome = Post.where(category: "Crafts", location:"Home")
  end
  def drinks
    @postsDrinksAba = Post.where(category: "Drinks", location:"ABA")
    @postsDrinksHome = Post.where(category: "Drinks", location:"Home")
  end
  def feelings
    @postsFeelingsAba = Post.where(category: "Feelings", location:"ABA")
    @postsFeelingsHome = Post.where(category: "Feelings", location:"Home")
  end
  def food
    @postsFoodAba = Post.where(category: "Food", location:"ABA")
    @postsFoodHome = Post.where(category: "Food", location:"Home")
  end
  def people
    @postsPeopleAba = Post.where(category: "People", location:"ABA")
    @postsPeopleHome = Post.where(category: "People", location:"Home")
  end
  def places
    @postsPlacesAba = Post.where(category: "Places", location:"ABA")
    @postsPlacesHome = Post.where(category: "Places", location:"Home")
  end

  # GET /posts/new
  def new
    @post = Post.new
  end

  # GET /posts/1/edit
  def edit
  end

  # POST /posts or /posts.json
  def create
    @post = Post.new(post_params.merge(user_id: current_user.id))

    respond_to do |format|
      if @post.save
        format.html { redirect_to post_url(@post), notice: "Post was successfully created." }
        format.json { render :show, status: :created, location: @post }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @post.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /posts/1 or /posts/1.json
  def update
    respond_to do |format|
      if @post.update(post_params)
        format.html { redirect_to post_url(@post), notice: "Post was successfully updated." }
        format.json { render :show, status: :ok, location: @post }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @post.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /posts/1 or /posts/1.json
  def destroy
    @post.destroy

    respond_to do |format|
      format.html { redirect_to posts_url, notice: "Post was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_post
      @post = Post.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def post_params
      params.require(:post).permit(:title, :image, :category, :location, :sound)
    end
end
