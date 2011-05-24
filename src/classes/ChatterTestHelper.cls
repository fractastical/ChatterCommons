/**
 * Contains a series of helper methods, specifically around populating records, subscribing to them, and commenting on
 * them to assist in writing Chatter related test cases
 * author: Quinton Wall - qwall@salesforce.com
 */
public class ChatterTestHelper 
{

	//--------------Users -----------------
	public static List<User> getUsers()
	{
		return [select id, name, profile.name from User where isActive = true LIMIT 100];
	}
	
	static testMethod void testGetUsers()
	{
		System.assert(ChatterTestHelper.getUsers().size() > 0);
	}
	
	public static List<User> getAdminUsers()
	{
		return [select id, name, profile.name from User where isActive = true And profile.name = 'System Administrator' LIMIT 100];
	}
	
	static testMethod void testGetAdminUsers()
	{
		System.assertEquals(ChatterTestHelper.getAdminUsers().get(0).profile.name,'System Administrator');
	}
	
	//-------------- Accounts --------------
	public static List<Account> createAccounts(Integer num)
	{
		List<Account> accts = new List<Account>();
		Account a = null;
		for(Integer i = 0; i < num; i++)
		{
			accts.add(new Account(name='Test Account'+i));
		}
		
		if(!accts.isEmpty())
			insert accts;
		
		return accts;
	}
	
	static testMethod void testCreateAccounts()
	{
		System.assertEquals(ChatterTestHelper.createAccounts(3).size(), 3);
	}
	
	//-------------- Opportunities --------------
	public static List<Opportunity> createOpportunities(Integer num)
	{
		List<Opportunity> optys = new List<Opportunity>();
		Opportunity a = null;
		Date d = date.today();
		for(Integer i = 0; i < num; i++)
		{
			optys.add(new Opportunity(name='Test Opportunity'+i, stagename='Prospecting',closedate=d+7));
		}
		
		if(!optys.isEmpty())
			insert optys;
		
		return optys;
	}
	
	static testMethod void testCreateOpportunities()
	{
		System.assertEquals(ChatterTestHelper.createOpportunities(5).size(), 5);
	}
	
	//-------------- Cases --------------
	public static List<Case> createCases(Integer num)
	{
		List<Case> c = new List<Case>();
		Case a = null;
		for(Integer i = 0; i < num; i++)
		{
			c.add(new Case(status='Working', origin='Web'));
		}
		
		if(!c.isEmpty())
			insert c;
		
		return c;
	}
	
	static testMethod void testCreateCases()
	{
		System.assertEquals(ChatterTestHelper.createCases(10).size(), 10);
	}
	
	//-------------- entities ----------------------
	/**
	 * 
	 */
	public static void followEntities(List<SObject> sobjs, String userid)
	{
		//yay, we can use the new generic sobject list in spring 10
		List<EntitySubscription> etys = new List<EntitySubscription>();
		
		for(SObject so : sobjs)
				etys.add(new EntitySubscription(parentid=so.id, subscriberid=userid));
		
		if(!etys.isEmpty())
		{
			//dont throw errors in results already exist
			Database.SaveResult[] lsr = Database.insert(etys, false); 
		}
		
	}
	
	static testMethod void testFollowEntities()
	{
		User u = ChatterTestHelper.getAdminUsers().get(0);
		
		System.runAs(u)
		{
			ChatterTestHelper.followEntities(ChatterTestHelper.createAccounts(5), u.id);
			List<AggregateResult> ar = 
				[select COUNT(id) cid from EntitySubscription where subscriberid = :u.id];
				
			Integer count = (Integer)ar.get(0).get('cid');
			System.assert(count >= 5);
		}
	}
	


    //------------------generic ---------------------
	/**
	 * set up a bunch of dummy accounts and subscriptions
	 * return a user in the system to be the one we run the rest as
	 * pass in 999 if you want an admin user
	 * pass in 0 to get a user with humans following them
	 */
	public static User setupAccountDataAndFollowers(Integer userToReturn, Integer acctsToCreate)
	{
		List<Account> acctsToAdd = new List<Account>();
		
		for(Integer i = 0; i < acctsToCreate; i++)
			acctsToAdd.add(new Account(name='TestAcct'+1)); 

		insert acctsToAdd;
		
		
		Integer counter = 0;
		Id prevUserId = null;
		List<EntitySubscription> allES = new List<EntitySubscription>();
		List<FeedComment> comments = new List<FeedComment>();
		List<User> allUsers = [select id, name, profile.name from User where isActive = true LIMIT 10];
		
		User adminUser = null;
		
		//randomly(ish) add some followers
		for(User u :  allUsers)
		{
			if(adminUser == null && u.profile.name == 'System Administrator')
				adminUser = u;
				
			if(counter >= 0 && counter < 5)
			{
				EntitySubscription es1 = null;
				
				for(Integer i = 3; i < 6; i++)
				{
					es1 = new EntitySubscription();
					es1.parentid = acctsToAdd.get(i).id;
					es1.subscriberid = u.id;
					allES.add(es1);
				}
			}
			//only add human followers to the first record.
			if(counter == 0 && allUsers.size() > 3)
			{
				System.debug(LoggingLevel.INFO, 'Adding Humans to:'+u.id);
				EntitySubscription es2 = new EntitySubscription();
				es2.parentid = allUsers.get(2).id;
				es2.subscriberid = u.id;
				allES.add(es2);
						
				EntitySubscription es2a = new EntitySubscription();
				es2a.parentid = allUsers.get(3).id;
				es2a.subscriberid = u.id;
				allES.add(es2a);
			}
			
			if(counter >=5 && counter < 10)
			{
				EntitySubscription es3 = null;
				
				for(Integer ia = 10; ia < 20; ia++)
				{
					es3 = new EntitySubscription();
					es3.parentid = acctsToAdd.get(ia).id;
					es3.subscriberid = u.id;
					allES.add(es3);
				}
			}
			
			counter++;
			prevUserId = u.id;
		}
		
		insert allES;
		
		User returnU = null;
		if(userToReturn == 999)
			returnU =  adminUser;
		else if(allUsers.size() >= userToReturn)
			returnU = allUsers.get(userToReturn-1);
		else
			returnU = allUsers.get(0);
		
		return returnU;
	}
	
	static testMethod void testSetupData()
	{
		
		User u = ChatterTestHelper.setupAccountDataAndFollowers(999, 30);
		List<AggregateResult> ar = [select COUNT(id) cid from Account where createdby.id = :UserInfo.getUserId()];
		Integer count = (Integer)ar.get(0).get('cid');
		System.assert(count >= 30);
	}
	
	static testMethod void testSetupDataOtherUser()
	{
		System.assert(ChatterTestHelper.setupAccountDataAndFollowers(1, 30) != null);
	}
	
	static testMethod void testSetupDataTooLargeUserRequest()
	{
		System.assert(ChatterTestHelper.setupAccountDataAndFollowers(50, 30) != null);
	}
	
		public static User createTestUser() {
		Profile p = [Select Id, Name from Profile where Name = 'System Administrator'];
		return TestUtility.createTestUser(p);
	}
	
	public static User createTestUser(Profile p) {
		
		String namePrefix = createRandomWord();
		
		AggregateResult[] userCount = [Select count(id) userCount From user where username like :namePrefix];
		
		Object users = userCount[0].get('userCount');
		
		User testUser = new User();
		testUser.Email = 'test@test.com';
		testUser.Username = namePrefix+users+'@testuser.com';

		testUser.LastName = 'test';
		testUser.Alias = 'test';
		testUser.ProfileId = p.Id;
		testUser.LanguageLocaleKey = 'en_US';
		testUser.LocaleSidKey = 'en_US';
		testUser.TimeZoneSidKey = 'America/Chicago';
		testUser.EmailEncodingKey = 'UTF-8';
		insert testUser;
		return testUser;
	}
	
	public static String createRandomWord() {
    	
    	String ret = 'word' + math.rint(math.random() * 100000);
    	
    	return ret;
    	
    }
	
}