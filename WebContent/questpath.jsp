<!-- 
	Gamegogy Leaderboard 1.0
    Copyright (C) 2012  David Thornton

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
-->

<%@page import="blackboard.data.gradebook.impl.Grade"%>
<%@page import="blackboard.data.content.avlrule.GradeRangeCriteria"%>
<%@page import="blackboard.persist.gradebook.impl.OutcomeDefinitionDbLoader"%>
<%@page import="blackboard.data.gradebook.impl.OutcomeDefinition"%>
<%@page import="blackboard.data.gradebook.impl.Outcome"%>
<%@page import="blackboard.persist.gradebook.impl.OutcomeDbLoader"%>
<%@page import="blackboard.data.content.avlrule.GradeCompletedCriteria"%>
<%@page import="blackboard.data.content.avlrule.AvailabilityCriteria"%>
<%@page import="blackboard.data.content.avlrule.AvailabilityRule"%>
<%@page import="blackboard.persist.content.avlrule.AvailabilityRuleDbLoader"%>
<%@page import="blackboard.persist.content.avlrule.ACLUserPredicateDbLoader"%>
<%@page import="blackboard.data.content.AggregateReviewStatus"%>
<%@page import="blackboard.data.gradebook.Score"%>
<%@page import="blackboard.data.gradebook.Lineitem"%>
<%@page import="blackboard.persist.gradebook.LineitemDbLoader"%>
<%@page import="blackboard.platform.BbServiceManager"%>
<%@page import="blackboard.data.navigation.CourseToc"%>
<%@page import="blackboard.persist.content.impl.ContentDbLoaderImpl"%>
<%@page import="blackboard.persist.navigation.CourseTocDbLoader"%>
<%@page import="blackboard.platform.coursemap.CourseMapManagerFactory"%>
<%@page import="blackboard.platform.coursemap.impl.CourseMapManagerImpl"%>
<%@page import="blackboard.platform.coursemap.CourseMapManager"%>
<%@page import="blackboard.platform.coursecontent.CourseContentManagerFactory"%>
<%@page import="blackboard.platform.coursecontent.CourseContentManager"%>
<%@page import="blackboard.persist.content.avlrule.AvailabilityCriteriaDbLoader"%>
<%@page import="blackboard.platform.coursecontent.impl.CourseContentManagerImpl"%>
<%@page import="blackboard.platform.content.ContentUserManagerImpl"%>
<%@page import="blackboard.data.content.Content"%>
<%@page import="blackboard.data.content.ContentManager"%>
<%@page import="blackboard.base.*"%>
<%@page import="blackboard.data.course.*"%> 				<!-- for reading data -->
<%@page import="blackboard.data.user.*"%> 					<!-- for reading data -->
<%@page import="blackboard.persist.*"%> 					<!-- for writing data -->
<%@page import="blackboard.persist.course.*"%> 				<!-- for writing data -->
<%@page import="blackboard.persist.content.*"%> 				<!-- for writing data -->
<%@page import="blackboard.data.coursemap.impl.*"%> 				<!-- for writing data -->
<%@page import="blackboard.platform.gradebook2.*"%>
<%@page import="blackboard.platform.gradebook2.impl.*"%>
<%@page import="java.util.*"%> 								<!-- for utilities -->
<%@page import="blackboard.platform.plugin.PlugInUtil"%>	<!-- for utilities -->
<%@ taglib uri="/bbData" prefix="bbData"%> 					<!-- for tags -->
<bbData:context id="ctx">  <!-- to allow access to the session variables -->
<%

	
	// get the current user
	User sessionUser = ctx.getUser();
	Id courseID = ctx.getCourseId();		
	String sessionUserRole = ctx.getCourseMembership().getRoleAsString();	
	String sessionUserID = sessionUser.getId().toString();	
	
	// use the GradebookManager to get the gradebook data
	GradebookManager gm = GradebookManagerFactory.getInstanceWithoutSecurityCheck();
	BookData bookData = gm.getBookData(new BookDataRequest(courseID));
		List<GradableItem> lgm = gm.getGradebookItems(courseID);
	CourseManager cm1 = CourseManagerFactory.getInstance();
	Course course = cm1.getCourse(courseID);
	
// 	//QUESTPATH WORK	
// 	String contentString = "";
// 	CourseContentManager ccmI = CourseContentManagerFactory.getInstance();
// 	CourseMapData cmD = new CourseMapData(course);
// 	ContentDbLoader cdbLoader= ContentDbLoader.Default.getInstance();
// 	List<Content> contents = cdbLoader.loadByCourseIdAndTitle(courseID, "Content");
	
	
// // 	Collection<Content> contentList =  cmD.getContentMap().values();
// // 	Iterator<Content> xyz = contentList.iterator();
// // 	while (xyz.hasNext()) {
// // 				Content c = (Content) xyz.next();
// // 				contentString += c.getTitle() + " ";
// // 	}

// 	for (Content content : contents) {
// 		contentString = contentString + " " + content.getTitle();
// 	}

// 	//QUESTPATH WORK
	
// 	String _categories =  "";
// 	for (GradableItem gi : lgm) {
// 		_categories = _categories + gi.getCategory();
// 	}
	// it is necessary to execute these two methods to obtain calculated students and extended grade data
	bookData.addParentReferences();
	bookData.runCumulativeGrading();
	// get a list of all the students in the class
	List <CourseMembership> cmlist = CourseMembershipDbLoader.Default.getInstance().loadByCourseIdAndRole(courseID, CourseMembership.Role.STUDENT, null, true);
	Iterator<CourseMembership> i = cmlist.iterator();
	
	// instructors will see student names
	boolean isUserAnInstructor = false;
	if (sessionUserRole.trim().toLowerCase().equals("instructor")) {
		isUserAnInstructor = true;
	}	
	Double scoreToHighlight = -1.0;
	int index = 0;
	
	while (i.hasNext()) {	
		CourseMembership cm = (CourseMembership) i.next();
		String currentUserID = cm.getUserId().toString();
		
		for (int x = 0; x < lgm.size(); x++){			
			GradableItem gi = (GradableItem) lgm.get(x);					
			GradeWithAttemptScore gwas2 = bookData.get(cm.getId(), gi.getId());
			Double currScore = 0.0;	
			
			if(gwas2 != null && !gwas2.isNullGrade()) {
				currScore = gwas2.getScoreValue();	 
			}						
			if (gi.getTitle().trim().toLowerCase().equalsIgnoreCase("total")) {
				if (sessionUserID.equals(currentUserID)) {
					scoreToHighlight = currScore;
				}
			}		
		}
		index = index + 1;
	}
		
	String jsPath = PlugInUtil.getUri("dt", "questpathblock", "js/highcharts.js");
	
	

%>

<!DOCTYPE HTML>
	<html>
	<head>
		<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
		<title>Vital Statistics</title>
		
		<script type="text/javascript" src="https://ajax.googleapis.com/ajax/libs/jquery/1.6.1/jquery.min.js"></script>
		<script type="text/javascript" src=<%=jsPath%>></script>
	</head>
	<body>
		<div id="questpathBlockChartContainer">
			<%= course.getTitle() %>
			<%
			//****BELOW IS CODE THAT HAS BEEN COMPLETED TO SHOW the following
			//    How to gather list of Content for a course
			//    How to get a list of items that compose the gradebook
			//    How to get a students grade(s) associated to the gradebook items
			//    How to get if rules are associated with assignments
   
			
					
 			CourseTocDbLoader courseTocLoader = (CourseTocDbLoader)BbServiceManager.getPersistenceService().getDbPersistenceManager().getLoader(CourseTocDbLoader.TYPE);
 			ContentDbLoader contentDbLoader = (ContentDbLoader)BbServiceManager.getPersistenceService().getDbPersistenceManager().getLoader(ContentDbLoader.TYPE);

 			//Gather the classes TABLE OF CONTENTS		
 			ArrayList tocList = courseTocLoader.loadByCourseId(courseID);
 			Iterator tocIterator = tocList.iterator();
 			out.println("Content TOC <br />");
 			while(tocIterator.hasNext())
 			{
 				CourseToc cToc = (CourseToc)tocIterator.next();
 				if(cToc.getTargetType()==CourseToc.Target.CONTENT)
 				{
 					//Load the content of the course
 					List children = contentDbLoader.loadChildren(cToc.getContentId(), false, null);
 					//BELOW IS FOR DEBUG Purposes to print the content title and data type
 					for(int j=0; j < children.size(); j++)
 					{
 						Content c = (Content)children.get(j);
 						out.println(c.getTitle() + " " + c.getDataType().getName() +  " " + c.getId() + "<br />");
 					}
 				}
 			}

			
			try {
			LineitemDbLoader lineItemDbLoader = LineitemDbLoader.Default.getInstance();
			
			//Load lineItems that compose the gradebook
			BbList<Lineitem> lineItems = lineItemDbLoader.loadByCourseId(courseID);
			out.println("<br/ > Scores <br />");
			out.println(ctx.getCourseMembership().getId() + " - User Id <br />");
				for (Lineitem li : lineItems) {
					out.println("Line Item - " + li.getName() + "=" + li.getType() + " " + li.getIsAvailable() + "<br />");
					if (li.getType().equals("Assignment") || li.getType().equals("Test")) {
					BbList<Score> scores = li.getScores();
			//For each score received for the line item print out a students results if that is the student currently logged in					
					for (Score score : scores) {
						if(score.getCourseMembershipId().equals(ctx.getCourseMembership().getId())) {
						out.println(li.getName() + " " + li.getPointsPossible()  + " " + score.getOutcome().getScore() + "<br />");
						}
					}
					}
				}
			}
			catch (Exception e) 
			{
				out.println("Error getting LineItems <br />");
			}
			
			try{
				AvailabilityRuleDbLoader avRuleLoader = AvailabilityRuleDbLoader.Default.getInstance();
				AvailabilityCriteriaDbLoader avCriLoader = AvailabilityCriteriaDbLoader.Default.getInstance();
				OutcomeDefinitionDbLoader defLoad = OutcomeDefinitionDbLoader.Default.getInstance();
				
				//Load ADAPTIVE RELEASE rules
				List<AvailabilityRule> rules = avRuleLoader.loadByCourseId(courseID);
				out.println("<br />Rules " + rules.size() + " <br/>");
				for(AvailabilityRule rule : rules) {
					//for each ADAPTIVE RELEASE rule, see the criteria
					List<AvailabilityCriteria> criterias = avCriLoader.loadByRuleId(rule.getId());
					out.println("<br />Criteria " + criterias.size() + " " + rule.getTitle() + " " + rule.getContentId() + " <br/>");
						for (AvailabilityCriteria criteria : criterias) {
							out.println(criteria.getRuleType().toString() + "<br />");
							//for each GRADE related criteria see which assignment the grade criteria is dependent upone
							if(criteria.getRuleType().equals(AvailabilityCriteria.RuleType.GRADE_RANGE)) {
								GradeRangeCriteria gcc = (GradeRangeCriteria) criteria;
								out.println(gcc.getRuleTypeLabel());
								out.println("GCC - " + gcc.getMinScore() + "<br />");
 								OutcomeDefinition definition = defLoad.loadById(gcc.getOutcomeDefinitionId());
 								out.println(" Outcome - " + definition.getTitle() + definition.getDisplayTitle() + " " + definition.getDescription() +"<br /");
							
							}
							if(criteria.getRuleType().equals(AvailabilityCriteria.RuleType.GRADE_RANGE_PERCENT)) {
								GradeRangeCriteria gcc = (GradeRangeCriteria) criteria;
								out.println(gcc.getRuleTypeLabel());
								out.println("GCC - " + gcc.getMinScore() + "<br />");
								OutcomeDefinition definition = defLoad.loadById(gcc.getOutcomeDefinitionId());
 								out.println(" Outcome - " + definition.getTitle() + "<br /");
							
							}
					}
				}
				//This was done just to show all the various outcome rules defined for a course
 				List<OutcomeDefinition> definitions = defLoad.loadByCourseId(courseID);
 				out.println("<br/> OUTCOME DEFINITIONS <br />");
 				for (OutcomeDefinition definition : definitions) {
 					out.println(definition.getDescription() + " " + definition.getTitle() + "<br />");
 				}
	
			}
			catch (Exception e) 
			{
				out.println("Error getting Aggregate Review Status <br />" + e.getLocalizedMessage());
			}
			
			//List the gradable items
			out.println("<br /> Gradable Items <br />");
			for (GradableItem giX : lgm) {
				out.println(giX.getTitle() + "<br />");				
			}
			
//EXAMPLE OUTPUT			
/*Jonathan Leftwich Test 
CourseContent TOC 
CP1 blackboard.data.content.Content PkId{key=_20_1, dataType=blackboard.data.content.Content, container=blackboard.persist.DatabaseContainer@43da850}
CP2 blackboard.data.content.Content PkId{key=_21_1, dataType=blackboard.data.content.Content, container=blackboard.persist.DatabaseContainer@43da850}
MySurvey blackboard.data.content.CourseLink PkId{key=_23_1, dataType=blackboard.data.content.Content, container=blackboard.persist.DatabaseContainer@43da850}
GUI Master blackboard.data.content.CourseDocument PkId{key=_24_1, dataType=blackboard.data.content.Content, container=blackboard.persist.DatabaseContainer@43da850}
Test1 blackboard.data.content.CourseLink PkId{key=_27_1, dataType=blackboard.data.content.Content, container=blackboard.persist.DatabaseContainer@43da850}

Scores 
PkId{key=_38_1, dataType=blackboard.data.course.CourseMembership, container=blackboard.persist.DatabaseContainer@43da850} - User Id 
Line Item - Weighted Total=Weighted Total true
Line Item - CP1=Assignment true
Line Item - CP2=Assignment true
Line Item - Running Total= true
Line Item - Total=Total true
Line Item - MySurvey=Survey true
MySurvey 0.0 0.0
Line Item - Test1=Test true

Rules 2 

Criteria 1 Rule 1 PkId{key=_21_1, dataType=blackboard.data.content.Content, container=blackboard.persist.DatabaseContainer@43da850} 
blackboard.data.content.avlrule.AvailabilityCriteria$RuleType:GRADE_RANGE_PERCENT
Grade GCC - 80.0
Outcome - CP1

Criteria 2 Rule 1 PkId{key=_24_1, dataType=blackboard.data.content.Content, container=blackboard.persist.DatabaseContainer@43da850} 
blackboard.data.content.avlrule.AvailabilityCriteria$RuleType:GRADE_RANGE
Grade GCC - 16.0
Outcome - CP1 null
Grade GCC - 25.0
Outcome - CP2 null

OUTCOME DEFINITIONS 
The weighted sum of all grades for a user based on item or category weighting. Weighted Total
null CP1
null CP2
Running Total
The unweighted sum of all grades for a user. Total
null MySurvey
null Test1

Gradable Items 
Weighted Total
CP1
CP2
XP GUI
Total
MySurvey
Test1
*/
			
			%>
		</div>		
 	</body>
</html>
</bbData:context>