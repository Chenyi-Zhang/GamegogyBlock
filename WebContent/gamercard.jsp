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

        //create a student class to hold their grades and other info
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
        Student currStudent = new Student(null, null, null, null, null, null, null);
        currStudent.firstName = ctx.getUser().getGivenName();
        currStudent.lastName = ctx.getUser().getFamilyName();
        if (ctx.getUser().getGender().toString().trim().toLowerCase().equalsIgnoreCase("blackboard.data.user.User$Gender:FEMALE")){
        	currStudent.isFemale = true;
        }
        else if (ctx.getUser().getGender().toString().trim().toLowerCase().equalsIgnoreCase("blackboard.data.user.User$Gender:MALE")){
        	currStudent.isFemale = false;
        }
        // get the current user
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

        
        Double scoreToHighlight = -1.0;
        int index = 0;
        
        while (i.hasNext()) {   
                CourseMembership cm = (CourseMembership) i.next();
                String currentUserID = cm.getUserId().toString();
                
                for (int x = 0; x < lgm.size(); x++){                   
                        GradableItem gi = (GradableItem) lgm.get(x);
                        GradeWithAttemptScore gwas2 = bookData.get(cm.getId(), gi.getId());
                        Double currScore = 0.0;
                        String currInventory = "";
                        String currGold = "";
                                                
                        if(gwas2 != null && !gwas2.isNullGrade()) {
                                currInventory = gwas2.getTextValue();
                        }
                        if(gwas2 != null && !gwas2.isNullGrade()) {
                                currScore = gwas2.getScoreValue();
                        }
                        if(gwas2 != null && !gwas2.isNullGrade()) {
                                currGold = gwas2.getTextValue();
                        }
                        if (gi.getTitle().trim().toLowerCase().equalsIgnoreCase("inventory")) {
                                if (sessionUserID.equals(currentUserID)) {
                                        currStudent.inventory = currInventory;
                                }
                        }
                        if (gi.getTitle().trim().toLowerCase().equalsIgnoreCase("gold")) {
                                if (sessionUserID.equals(currentUserID)) {
                                        currStudent.gold = currGold;
                                }
                        }
                        if (gi.getTitle().trim().toLowerCase().equalsIgnoreCase("total")) {
                                if (sessionUserID.equals(currentUserID)) {
                                        currStudent.score = currScore;
                                }
                        }
                        
                }
                index = index + 1;
        }
        
        if( currStudent.score <100){ currStudent.playerLevel = "1";}
        if( currStudent.score >=100 && currStudent.score < 300){ currStudent.playerLevel = "2";}
        if( currStudent.score >=300 && currStudent.score < 600){ currStudent.playerLevel = "3";}
        if( currStudent.score >=600 && currStudent.score < 1000){ currStudent.playerLevel = "4";}
        if( currStudent.score >=1000){ currStudent.playerLevel = "5";}
        
        double max = 0; 
        double xpnextlevel = 0;
        if( currStudent.playerLevel.trim().toLowerCase().equalsIgnoreCase("1")) {
                max = 100; 
                xpnextlevel = max - currStudent.score; 
        }
        if( currStudent.playerLevel.trim().toLowerCase().equalsIgnoreCase("2")){ 
                max = 300; 
                xpnextlevel = max - currStudent.score;
        }
        if ( currStudent.playerLevel.trim().toLowerCase().equalsIgnoreCase("3")){ 
                max = 600;
                xpnextlevel = max - currStudent.score;
        }
        if ( currStudent.playerLevel.trim().toLowerCase().equalsIgnoreCase("4")){ 
                max =1000; 
                xpnextlevel = max - currStudent.score;
        }
        out.println(currStudent.firstName);
        out.println(currStudent.lastName + "<br>");
        out.println(currStudent.inventory + "<br>");
        out.println("Gold:");
        out.println(currStudent.gold  + "<br>");
        out.println("Player Level:");
        out.println(currStudent.playerLevel + "<br>");
        out.println("Your Score:");
        out.println(currStudent.score);
        out.println("/");
        out.println(max);
        out.println("<br>");
        out.println("XP To next level:");
        out.println(xpnextlevel);
        out.println("<br>");
        out.println(currStudent.isFemale + "<br>");
        out.println("Inventory:<br>");
		Scanner input = new Scanner(currStudent.inventory).useDelimiter("/");
		String item = "";
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
					out.print(quantity);
					out.print(" X Scroll of Lockpicking<br>");
				}
				if(itemID.trim().toLowerCase().equalsIgnoreCase("B")) {
					out.print(quantity);
					out.print(" X Elixir of Time Control<br>");
				}
				if(itemID.trim().toLowerCase().equalsIgnoreCase("C")) {
					out.print(quantity);
					out.print(" X A Hat<br>");
				}
				if(itemID.trim().toLowerCase().equalsIgnoreCase("D")) {
					out.print(quantity);
					out.print(" X Another Hat<br>");
				}
				if(itemID.trim().toLowerCase().equalsIgnoreCase("E")) {
					out.print(quantity);
					out.print(" X HATS! HATS! HATS! HATS!<br>");
				}
			}
		}

        
        String imagePath = PlugInUtil.getUri("dt", "gamercardblock", "images/");
        
%>
<!DOCTYPE html>
<html>
<head>
	<link href="http://ajax.googleapis.com/ajax/libs/jqueryui/1.8/themes/base/jquery-ui.css" rel="stylesheet" type="text/css"/>
	<script src="http://ajax.googleapis.com/ajax/libs/jquery/1.5/jquery.min.js"></script>
	<script src="http://ajax.googleapis.com/ajax/libs/jqueryui/1.8/jquery-ui.min.js"></script>
	<script>
		var currStudentscore = <%=currStudent.score%>;
		var max =<%=max%>;
		var thegender = <%=currStudent.isFemale%>;
		$(document).ready(
			function() {
					$("#progressbar").progressbar({max: max, value: currStudentscore, showtext:true,percentage:true});
					if (thegender == true){
						$("#avatar").append('<img src="<%=imagePath%>female.png">');
					}
					else if (thegender == false) {
						$("#avatar").append('<img src="<%=imagePath%>male.png">');
					}
			}

		);

	</script>
</head>
<body>

<div id="progressbar"></div>
<div id="avatar"></div>

</body>
</html>

</bbData:context>