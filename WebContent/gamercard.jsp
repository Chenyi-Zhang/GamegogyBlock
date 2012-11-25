<%@page import="blackboard.base.*"%>
<%@page import="blackboard.data.course.*"%>                             <!-- for reading data -->
<%@page import="blackboard.data.user.*"%>                                       <!-- for reading data -->
<%@page import="blackboard.data.user.User.Gender"%> 
<%@page import="blackboard.persist.*"%>                                         <!-- for writing data -->
<%@page import="blackboard.persist.course.*"%>                          <!-- for writing data -->
<%@page import="blackboard.platform.gradebook2.*"%>
<%@page import="blackboard.platform.gradebook2.impl.*"%>
<%@page import="java.util.*"%>
<%@page import="java.util.Scanner"%>                                                          <!-- for utilities -->
<%@page import="blackboard.platform.plugin.PlugInUtil"%>        <!-- for utilities -->
<%@ taglib uri="/bbData" prefix="bbData"%>                                      <!-- for tags -->
<bbData:context id="ctx">  <!-- to allow access to the session variables -->
<%
	//create a student class to hold their XP and other info
	final class Student{
		public Double score;
		public String firstName;
		public String lastName;
		public String inventory;
		public String playerLevel;
		public String gold;
		public Boolean isFemale;
		public Student(String firstName, String lastName, Double score, String inventory, String playerLevel, String gold, Boolean isFemale) {
			this.score = score;
			this.firstName = firstName;
			this.lastName = lastName;
			this.inventory = inventory;
			this.playerLevel = playerLevel;
			this.gold = gold;
			this.isFemale = isFemale;
		}
	} //end of class Student
	
	//instantiate a student object with default values
	Student currStudent = new Student("", "", 0., "", "1", "0", false);
    
	//initialize parameters needed for calculations, etc.
	double max = 0; 
	double xpnextlevel = 0;
	double barValue = 0;
	String inventoryString = "";
	String XPstatus = "";
	boolean atMaxLevel = false;
	boolean foundInventory = false;
	boolean foundTotal = false;
	boolean foundGold = false;
	
	//check whether user is student or instructor
	String sessionUserRole = ctx.getCourseMembership().getRoleAsString();
	boolean isUserAnInstructor = false;
	if (sessionUserRole.trim().toLowerCase().equals("instructor")) {
		isUserAnInstructor = true;
	}
	
	//begin retrieving information if user is not instructor
	if (!isUserAnInstructor) {
		
		//retrieve student's name
		currStudent.firstName = ctx.getUser().getGivenName();
		currStudent.lastName = ctx.getUser().getFamilyName();
		
		//retrieve student's gender
		if (ctx.getUser().getGender().toString().trim().toLowerCase().equalsIgnoreCase("blackboard.data.user.User$Gender:FEMALE")){
			currStudent.isFemale = true;
		}
		else if (ctx.getUser().getGender().toString().trim().toLowerCase().equalsIgnoreCase("blackboard.data.user.User$Gender:MALE")){
			currStudent.isFemale = false;
		}
		
		// get the current user's id; necessary to get gradebook info
		User sessionUser = ctx.getUser();
		Id courseID = ctx.getCourseId();                
		String sessionUserID = sessionUser.getId().toString();  
		
		// use the GradebookManager to get the gradebook data
		GradebookManager gm = GradebookManagerFactory.getInstanceWithoutSecurityCheck();
		BookData bookData = gm.getBookData(new BookDataRequest(courseID));
		List<GradableItem> lgm = gm.getGradebookItems(courseID);
		// it is necessary to execute these two methods to obtain calculated students and extended grade data
		bookData.addParentReferences();
		bookData.runCumulativeGrading();
		// get a list of all the students in the classs
		List <CourseMembership> cmlist = CourseMembershipDbLoader.Default.getInstance().loadByCourseIdAndRole(courseID, CourseMembership.Role.STUDENT, null, true);
		Iterator<CourseMembership> i = cmlist.iterator();
        
		//go through gradebook to set values for student
		while (i.hasNext()) {   
			CourseMembership cm = (CourseMembership) i.next();
			String currentUserID = cm.getUserId().toString();
			
				for (int x = 0; x < lgm.size(); x++){                   
					GradableItem gi = (GradableItem) lgm.get(x);
					GradeWithAttemptScore gwas2 = bookData.get(cm.getId(), gi.getId());
					Double currScore = 0.0;
					String currInventory = "";
					String currGold = "0";
					
                        if(gwas2 != null && !gwas2.isNullGrade()) {
                                currInventory = gwas2.getTextValue();
                                currScore = gwas2.getScoreValue();
                                currGold = gwas2.getTextValue();
                        }

                        if (sessionUserID.equals(currentUserID)) {
	                        if (gi.getTitle().trim().toLowerCase().equalsIgnoreCase("inventory")) {
	                                        currStudent.inventory = currInventory;
	                                        foundInventory = true;
	                        }
	                        if (gi.getTitle().trim().toLowerCase().equalsIgnoreCase("gold")) {
	                                        currStudent.gold = currGold;
	                                        foundGold = true;
	                        }
	                        if (gi.getTitle().trim().toLowerCase().equalsIgnoreCase("total")) {
	                                        currStudent.score = currScore;
	                                        foundTotal = true;
	                        }
                        }  
                }
        }
        
		//initialize student's player level
		if( currStudent.score <100){ currStudent.playerLevel = "1";}
		if( currStudent.score >=100 && currStudent.score < 300){ currStudent.playerLevel = "2";}
		if( currStudent.score >=300 && currStudent.score < 600){ currStudent.playerLevel = "3";}
		if( currStudent.score >=600 && currStudent.score < 1000){ currStudent.playerLevel = "4";}
		if( currStudent.score >=1000){ currStudent.playerLevel = "5";}
		
		//set paramters of progresss bar based on student's player level
		if( currStudent.playerLevel.trim().toLowerCase().equalsIgnoreCase("1")) {
			max = 100; 
			xpnextlevel = max - currStudent.score;
			barValue = (currStudent.score-0)/(max-0);
		}
		else if( currStudent.playerLevel.trim().toLowerCase().equalsIgnoreCase("2")){ 
			max = 300; 
			xpnextlevel = max - currStudent.score;
			barValue = (currStudent.score-100)/(max-100);
		}
		else if ( currStudent.playerLevel.trim().toLowerCase().equalsIgnoreCase("3")){ 
			max = 600;
			xpnextlevel = max - currStudent.score;
			barValue = (currStudent.score-300)/(max-300);
		}
		else if ( currStudent.playerLevel.trim().toLowerCase().equalsIgnoreCase("4")){ 
			max =1000; 
			xpnextlevel = max - currStudent.score;
			barValue = (currStudent.score-600)/(max-600);
		}
		else if ( currStudent.playerLevel.trim().toLowerCase().equalsIgnoreCase("5")){
			max = currStudent.score;
			xpnextlevel = 0;
			barValue = 100;
			atMaxLevel = true;
		}
        
		//create XP text for progress bar
		XPstatus = currStudent.score + "/" + max;
		
        //decode inventory
		Scanner input = new Scanner(currStudent.inventory).useDelimiter("/");
		String item = "";
		Boolean foundItem = false;
		while (input.hasNext()) {
			item = input.next();
			Scanner input2 = new Scanner(item).useDelimiter("\\.");
			int quantity = 0;
			if (input2.hasNextInt()) {
				quantity = input2.nextInt();
			}
			String itemID = input2.next();

			if(quantity > 0) {
				if(itemID.trim().toLowerCase().equalsIgnoreCase("A")) {
					inventoryString += quantity + " x Scroll of Lockpicking<br>";
					foundItem = true;
				}
				if(itemID.trim().toLowerCase().equalsIgnoreCase("B")) {
					inventoryString += quantity + " x Elixir of Time Control<br>";
					foundItem = true;
				}
				if(itemID.trim().toLowerCase().equalsIgnoreCase("C")) {
					inventoryString += quantity + " x A Hat<br>";
					foundItem = true;
				}
				if(itemID.trim().toLowerCase().equalsIgnoreCase("D")) {
					inventoryString += quantity + " x Another Hat<br>";
					foundItem = true;
				}
				if(itemID.trim().toLowerCase().equalsIgnoreCase("E")) {
					inventoryString += quantity + " x HATS! HATS! HATS! HATS!<br>";
					foundItem = true;
				}
			}
		}
		if (!foundItem) {
			inventoryString += "You have no items in your inventory.<br>";
		}
		
	} //end retrieval of student information
	
	//get path of images and doumentation folders
	String imagePath = PlugInUtil.getUri("dt", "gamercardblock", "images/");
	String docPath = PlugInUtil.getUri("dt", "gamercardblock", "Documents/");
%>
<!DOCTYPE html>
<html>
	<head>
		<link href="http://ajax.googleapis.com/ajax/libs/jqueryui/1.8/themes/base/jquery-ui.css" rel="stylesheet" type="text/css"/>
		<script src="http://ajax.googleapis.com/ajax/libs/jquery/1.5/jquery.min.js"></script>
		<script src="http://ajax.googleapis.com/ajax/libs/jqueryui/1.8/jquery-ui.min.js"></script>
		<script>
			var isInstructor = <%=isUserAnInstructor%>;
			//check if user is instructor to determine output
			if (!isInstructor) {
				//initialize information required for module objects
				var currStudentscore = <%=currStudent.score%>;
				var barValue = <%=barValue%>
				var max = <%=max%>;
				var thegender = <%=currStudent.isFemale%>;
				var atMaxLevel = <%=atMaxLevel%>
				var xpString = $('<div style="margin-top: 5px"><center><strong><%=XPstatus%></strong></center></div>');
				var maxXPString = $('<div id = "style="margin-top: 5px"><center>MAXIMUM LEVEL</center></div>');
				var divInventory = $('<div class = "inventory_scroll"><%=inventoryString%></div>');
				$(document).ready(
					function() {
							//output progress bar
							$("#progressbar").progressbar({max: 1, value: barValue, showtext:true,percentage:true});
                            $("#progressbar").css({ 'background': 'White' });
                            $("#progressbar > div").css({ 'background': '#339967' });
                            if (atMaxLevel) {
                            	$("#progressbar > div").append(maxXPString);
								$("#information_left").append('<strong><center>Current XP: <%=currStudent.score%></center></strong>');
                            }
                            else {
                            	if (barValue > 0){
                            		$("#progressbar > div").append(xpString);
                            	}
                            	else {
                            		$("#progressbar").append(xpString);
                            	}
                            	$("#information_left").append('<strong><center>Only <%=xpnextlevel%> XP to the next level!</center></strong>');
                            }
                            
                            //output inventory
							$("#information_left").append('<br><strong>Inventory:</strong>');
							$("#inventory").append(divInventory);
							
							//output avatarbased on student's gender
							if (thegender == true){
								$("#avatar").append('<img src="<%=imagePath%>female.png" width="120px" height="120px"><br>');
							}
							else {
								$("#avatar").append('<img src="<%=imagePath%>male.png" width="120px" height="120px"><br>');
							}
							
							//output other student informatio including name, gold, player level
							$("#avatar").append('<strong><center><%=currStudent.firstName%> '+'<%=currStudent.lastName%></center></strong>');
							$("#avatar").append('<center>Level <%=currStudent.playerLevel%></center>');
							$("#avatar").append('<center><%=currStudent.gold%> Gold</center>');
							
					}
				);
			}
			else {
				$(document).ready(
					function() {
						//output intructions to set up module
						$("#instructor").append("<h1>Welcome to the Gamercard Module!</h1>");
						$("#instructor").append("<p>Your students are now able to view their progress in your course with this module. To take full advantage of this module, please ensure that you have completed the following steps:</p>");
						$("#instructor").append("<h2>(1) Create a total column</h2><p><i>By default, a total column is included in the grade center of your course. To check if this column is included in your course:<br><br></i></p><p>Go to Grade Center -> Full Grade Center<br><br></p><p><i>If total is not included in your grade center, complete the following steps. Otherwise, skip to step (2).<br><br></i></p><p> Click Create Calculated Column -> Create Total Column</p><p>For Column Name enter total</p><p>For Primary Display select Score</p><p>For Include this Column in Grade Center Calculations select Yes</p><p>Click Submit</p>");
						$("#instructor").append("<h2>(2) Create a gold column</h2><p>Go to Grade Center -> Full Grade Center ->Create Column</p><p>For Column Name enter gold</p><p>For Primary Display select Score</p><p>For Point Possible type 0</p><p>Leave Dates Sections Blank</p><p>For Include this Column in Grade Center Calculations select No</p><p>Click Submit</p>");
						$("#instructor").append("<h2>(3) Create an inventory column</h2><p>Go to Grade Center -> Full Grade Center ->Create Column</p><p>For Column Name enter inventory</p><p>For Primary Display select Text</p><p>For Point Possible type 0</p><p>Leave Dates Sections Blank</p><p>For Include this Column in Grade Center Calculations select No</p><p>Click Submit</p>");
						$("#instructor").append("<p>You are now done! To include any assignments in calculation of XP, be sure that you have selected Yes for Include this Column in Grade Center Calculations for that assignment.</p>");
						$("#instructor").append("<br><p><a href=<%=docPath%>Gamercard_Module_Instructor_Manual.pdf>For More Information</a></p>");
					}
				);
			}
		</script>
	</head>
	<style>
		div.inventory_scroll {
			height:70px;
			overflow:auto;
		}
	</style>
	<body>
		<div id="avatar" style="float: right; margin-left: 30px"></div>
		<div id="progressbar"></div>
		<div id="information_left"></div>
		<div id="inventory"></div>
		<div id="instructor"></div>
		<div id="docs"></div>
	</body>
</html>

</bbData:context>