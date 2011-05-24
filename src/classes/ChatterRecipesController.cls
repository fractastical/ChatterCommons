/**
 * Controller which contains all the chatter recipes code and 100% test code coverage
 * Author: qwall@salesforce.com
 */

public class ChatterRecipesController 
{
	
	
	//----------------------------- RECIPE 1 ---------------------------------------
	//store the user status msg from Recipe 1
	public String recipeOneUserStatus  { get; set; }
	
	public PageReference recipeOneDoUserStatus()
	{
		 User user = [select id, CurrentStatus from User where id = :UserInfo.getUserId()];
        user.CurrentStatus = recipeOneUserStatus;
        update user;
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Status Updated'));
        
        return null;
	}
	
	static testMethod void testRecipeOne()
	{
		ChatterRecipesController crc = new ChatterRecipesController();
		crc.recipeOneUserStatus = 'test status';
		crc.recipeOneDoUserStatus();
		User user = [select id, CurrentStatus from User where id = :UserInfo.getUserId()];
		System.assertEquals(user.CurrentStatus, 'test status');
		 
	}
	
	//----------------------------- RECIPE 2 ---------------------------------------
	//doesnt need any APEX code
	
	//----------------------------- RECIPE 3 ---------------------------------------

    public List<EntitySubscription> getRecipeThreeGetFollowers()
    {
        
          // All users who are following us
        List<EntitySubscription> followers = [
        	select id, subscriberid, subscriber.name
            from EntitySubscription
            where parentid = :UserInfo.getUserId()
            order by subscriber.name LIMIT 100];
        
        return followers;
    }
    
    static testMethod void testRecipeThree()
    {
    	//add at some following records so we have at least one
    	List<User> users = [select id, name from User where id != :UserInfo.getUserId() LIMIT 10];
    	//make sure there is at least one other user in additon to me.
    	System.assertNotEquals(users.size(), 0);
    	
    	EntitySubscription es = null;
    	List<EntitySubscription> allES = new List<EntitySubscription>();
    	
    	for(User u : users)
    	{
    		es = new EntitySubscription();
    		es.parentid = UserInfo.getUserId();
    		es.subscriberid = u.id;
    		allES.add(es);
    	}
    	if(!allES.isEmpty())
    		Database.SaveResult[] lsr = Database.insert(allES, false);  //if record exists, fail-through quietly
    	
    	ChatterRecipesController crc = new ChatterRecipesController();
		
    	System.assert(crc.getRecipeThreeGetFollowers().size() > 0);
    	
    }
    
    //----------------------------- RECIPE 4 ---------------------------------------
     public List<EntitySubscription> getRecipeFourGetFollowing()
    {
       // Everyone we're following
        List<EntitySubscription> followingES = [
        	select id, parentid, subscriberid, parent.name
            from EntitySubscription
            where subscriberid = :UserInfo.getUserId()
            order by parent.name LIMIT 100];
        
       return followingES;
    }
    
    static testMethod void testRecipeFour()
    {
    	//add at some following records so we have at least one
    	List<User> users = [select id, name from User where id != :UserInfo.getUserId() LIMIT 10];
    	//make sure there is at least one other user in additon to me.
    	System.assertNotEquals(users.size(), 0);
    	
    	EntitySubscription es = null;
    	List<EntitySubscription> allES = new List<EntitySubscription>();
    	
    	for(User u : users)
    	{
    		es = new EntitySubscription();
    		es.parentid = u.id;
    		es.subscriberid = UserInfo.getUserId();
    		allES.add(es);
    	}
    	if(!allES.isEmpty())
    		Database.SaveResult[] lsr = Database.insert(allES, false);  //if record exists, fail-through quietly
    	
    	ChatterRecipesController crc = new ChatterRecipesController();
		
    	System.assert(crc.getRecipeFourGetFollowing().size() > 0);
    	
    }
    
    //----------------------------- RECIPE 5 ---------------------------------------
	//store the user entered feedpost from Recipe 5
	public String recipeFiveAddAFeedPost  { get; set; }
	
	public void recipeFiveAddPost()
	{
		  FeedPost fpost = new FeedPost();
            fpost.ParentId = UserInfo.getUserId();
            fpost.Body = recipeFiveAddAFeedPost;
            insert fpost;
		 
		 ApexPages.addMessage(new ApexPages.Message(
		 	ApexPages.Severity.INFO, 'FeedPost ID is:'+fpost.id));
	
		recipeFiveAddAFeedPost = '';
		
	}
	
	static testMethod void testRecipeFive()
	{
		List<AggregateResult> beforeAR = 
				[select COUNT(id) cid from UserFeed where parentid = :UserInfo.getUserId()];				
			Integer beforeC = (Integer)beforeAR.get(0).get('cid');
			
		ChatterRecipesController crc = new ChatterRecipesController();
		crc.recipeFiveAddAFeedPost = 'test post';
		crc.recipeFiveAddPost();
		
		List<AggregateResult> afterAR = 
				[select COUNT(id) cid from UserFeed where parentid = :UserInfo.getUserId()];		
			Integer afterC = (Integer)afterAR.get(0).get('cid');
		
		System.assert(afterC > beforeC);
		
	}
	
	 //----------------------------- RECIPE 6 ---------------------------------------
	//store the user entered comment from Recipe 6
	public String recipeSixComment  { get; set; }
	public String recipeSixFPostID  { get; set; }
	
	public void recipeSixAddAComment()
	{
		//need to pass in the feedpost id we captured from recipe 5 
		//(copy n paste it from recipe 5 tab)
		 List<UserFeed> myfeed = [SELECT Id, FeedPostId
		 						  FROM UserFeed 
		 						  WHERE feedpostid = :recipeSixFPostID LIMIT 1];
		 
		FeedComment fcomment = new FeedComment();
        fcomment.FeedItemId = myfeed.get(0).id; 
        fcomment.CommentBody = recipeSixComment;
        insert fcomment; 
		 
		recipeSixComment = '';
		 ApexPages.addMessage(
		 	new ApexPages.Message(ApexPages.Severity.INFO, 'Comment Added'));
	
	}
	
	static testMethod void testRecipeSix()
	{
		 FeedPost fpost = new FeedPost();
            fpost.ParentId = UserInfo.getUserId();
            fpost.Body = 'test post';
            insert fpost;
		
		ChatterRecipesController crc = new ChatterRecipesController();
		crc.recipeSixComment = 'test comment';
		crc.recipeSixFPostID = fpost.id;
		crc.recipeSixAddAComment();
		
		List<UserFeed> myfeed2 = [SELECT Id,
                                (SELECT Id, CommentBody, CreatedDate,
                                        CreatedById, CreatedBy.FirstName, CreatedBy.LastName
                                        FROM FeedComments ORDER BY CreatedDate, ID DESC)
                                FROM UserFeed
                                WHERE FeedPost.id = :fpost.id];
                                
        System.assert(myfeed2.get(0).FeedComments.size() > 0);
		
	}
    
    
    //------------------------ RECIPE 7 ----------------------------------------------
    public List<NewsFeed> getRecipeSevenNewsFeed()  {

	     List<NewsFeed> myfeed = 
	     	[SELECT Id, Type, 
            CreatedById, CreatedBy.FirstName, CreatedBy.LastName, CreatedDate,
            ParentId, Parent.Name, 
                FeedPostId, FeedPost.Body, FeedPost.Title, FeedPost.CreatedById, FeedPost.LinkUrl,
            (SELECT Id, FieldName, OldValue, NewValue 
                      FROM FeedTrackedChanges ORDER BY Id DESC), 
            (SELECT Id, CommentBody, CreatedDate,
                    CreatedById, CreatedBy.FirstName, CreatedBy.LastName
                    FROM FeedComments ORDER BY CreatedDate DESC, ID DESC LIMIT 10)
             FROM NewsFeed
             ORDER BY CreatedDate DESC, ID DESC
             LIMIT 50];
   
	       return myfeed;
	}
	
	static testMethod void testRecipeSeven()
	{
		ChatterRecipesController crc = new ChatterRecipesController();
		
		//add at least one post
		crc.recipeFiveAddAFeedPost = 'Test Post';
		crc.recipeFiveAddPost();
		
		System.assert(crc.getRecipeSevenNewsFeed().size() > 0);
	}
	
	//-------------------------- RECIPE 8 -------------------------------------
	 public List<Recommendation> getRecipeEightTopPosters() 
     {
        List<AggregateResult> results =  [
            SELECT ParentId pid, Parent.Name pname, COUNT(id) fcount 
            FROM UserFeed 
            WHERE Type='UserStatus' 
            AND CreatedDate = THIS_WEEK
            GROUP BY Parent.Name, ParentId
            ORDER BY Count(id) DESC LIMIT 10];
            
        List<Recommendation> top = new List<Recommendation>();
        Recommendation r = null;
        
        for (AggregateResult ar : results) 
        {
            r = new Recommendation();
            r.count = ar.get('fcount') + '';
            r.name = ar.get('pname')+'';
            r.entityid = ar.get('pid')+'';
            top.add(r);
        }
        return top;
    }
    
    static testMethod void testRecipeEight()
	{
		ChatterRecipesController crc = new ChatterRecipesController();
		
		//add at least one post
		crc.recipeFiveAddAFeedPost = 'Test Post';
		crc.recipeFiveAddPost();
		
		System.assert(crc.getRecipeEightTopPosters().size() > 0);
	}
    
    public List<AccountFeed> getRecipeNineFeedTrackedChanges()
    {
        List<AccountFeed> af = [Select id, Parent.Name,
        	(SELECT Id, FieldName, NewValue FROM FeedTrackedChanges) 
        	from AccountFeed LIMIT 100];
        
        for(AccountFeed f : af)
        {
            System.debug(f.FeedTrackedChanges.size());
            
            for(Integer i = 0; i < f.feedTrackedChanges.size(); i++)
                System.debug(LoggingLevel.INFO, 
                	'Change on '+f.feedTrackedChanges.get(i).fieldName+
                    ' is '+f.feedTrackedChanges.get(i).NewValue );
        }   
        return af;
     
    }
    
    static testMethod void testRecipeNine()
	{
		ChatterRecipesController crc = new ChatterRecipesController();
		
		List<Account> accts = new List<Account>();
		
		for(Account a : [select id, billingcity from Account LIMIT 10])
		{
			a.billingCity = 'bedrock';
			accts.add(a);
		}
		
		System.assert(accts.size() > 0);
		
		if(!accts.IsEmpty())
			update accts;
		
		System.assert(crc.getRecipeNineFeedTrackedChanges().size() > 0);
	}
    
}