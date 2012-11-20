<!-- 
	Gamegogy Quest Path 1.0
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

<%@page import="blackboard.persist.content.impl.ContentDbPersisterImpl"%>
<%@page import="blackboard.persist.content.avlrule.AvailabilityRuleDbPersister"%>
<%@page import="blackboard.data.gradebook.impl.Grade"%>
<%@page import="blackboard.data.content.avlrule.GradeRangeCriteria"%>
<%@page import="blackboard.persist.gradebook.impl.OutcomeDefinitionDbLoader"%>
<%@page import="blackboard.data.gradebook.impl.OutcomeDefinition"%>
<%@page import="blackboard.data.gradebook.impl.Outcome"%>
<%@page import="blackboard.persist.gradebook.impl.OutcomeDbLoader"%>
<%@page import="blackboard.data.content.avlrule.GradeCompletedCriteria"%>
<%@page import="blackboard.data.content.avlrule.AvailabilityCriteria"%>
<%@page import="blackboard.data.content.avlrule.AvailabilityRule"%>
<%@page	import="blackboard.persist.content.avlrule.AvailabilityRuleDbLoader"%>
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
<%@page	import="blackboard.platform.coursecontent.CourseContentManagerFactory"%>
<%@page import="blackboard.platform.coursecontent.CourseContentManager"%>
<%@page	import="blackboard.persist.content.avlrule.AvailabilityCriteriaDbLoader"%>
<%@page	import="blackboard.platform.coursecontent.impl.CourseContentManagerImpl"%>
<%@page import="blackboard.platform.content.ContentUserManagerImpl"%>
<%@page import="blackboard.data.content.Content"%>
<%@page import="blackboard.data.content.ContentManager"%>
<%@page import="blackboard.base.*"%>
<%@page import="blackboard.data.course.*"%>
<!-- for reading data -->
<%@page import="blackboard.data.user.*"%>
<!-- for reading data -->
<%@page import="blackboard.persist.*"%>
<!-- for writing data -->
<%@page import="blackboard.persist.course.*"%>
<!-- for writing data -->
<%@page import="blackboard.persist.content.*"%>
<!-- for writing data -->
<%@page import="blackboard.data.coursemap.impl.*"%>
<!-- for writing data -->
<%@page import="blackboard.platform.gradebook2.*"%>
<%@page import="blackboard.platform.gradebook2.impl.*"%>
<%@page import="java.util.*"%>
<!-- for utilities -->
<%@page import="blackboard.platform.plugin.PlugInUtil"%>
<%@page import="com.jsu.cs521.questpath.buildingblock.util.*" %>
<%@page import="com.jsu.cs521.questpath.buildingblock.object.*" %>
<%@page import="com.jsu.cs521.questpath.buildingblock.engine.*" %>
<!-- for utilities -->
<%@ taglib uri="/bbData" prefix="bbData"%>
<!-- for tags -->
<bbData:context id="ctx">
	<!-- to allow access to the session variables -->
	<%
	// get the current user
	User sessionUser = ctx.getUser();
	Id courseID = ctx.getCourseId();		
	String sessionUserRole = ctx.getCourseMembership().getRoleAsString();	
	String sessionUserID = sessionUser.getId().toString();	
	CourseManager cm1 = CourseManagerFactory.getInstance();
	Course course = cm1.getCourse(courseID);
	
	boolean isUserAnInstructor = false;
	if (sessionUserRole.trim().toLowerCase().equals("instructor")) {
		isUserAnInstructor = true;
	}	
		
//	String jsPath = PlugInUtil.getUri("dt", "questpathblock", "js/highcharts.js");
	String imagePath = PlugInUtil.getUri("dt", "questpathblock", "images/");
	String cssPath = PlugInUtil.getUri("dt", "questpathblock", "css/questPath.css");

%>

<!DOCTYPE HTML>
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<title>QuestPath 1.0.2</title>
<link rel="stylesheet" type="text/css" href="<%=cssPath %>" />
<script type="text/javascript" src="https://ajax.googleapis.com/ajax/libs/jquery/1.6.1/jquery.min.js"></script>
<%-- <script type="text/javascript" src=<%=jsPath%>></script> --%>
<script type="text/javascript">		
			jQueryAlias = $.noConflict();  //to avoid this webapp conflicting with others on the page
</script>
</head>
<body class="qp">
	<div id="questpathBlockContainer" class="qp">
		<%
		//Load Course Table of Content
 			CourseTocDbLoader cTocLoader = CourseTocDbLoader.Default.getInstance();
 			ContentDbLoader cntDbLoader = ContentDbLoader.Default.getInstance();
 			
 			List<CourseToc> tList = cTocLoader.loadByCourseId(ctx.getCourseId());
 			
 		//Create an ArrayList of Content based on the TOC
 			List<Content> children = new ArrayList<Content>();
 			for (CourseToc t : tList ) {
 				if (t.getTargetType() == CourseToc.Target.CONTENT) {
					children.addAll(cntDbLoader.loadChildren(t.getContentId(), false, null));
 				}
 			}
 			 			
		//Load grades for gradable Lineitems
 			LineitemDbLoader lineItemDbLoader = LineitemDbLoader.Default.getInstance();
			List<Lineitem> lineitems = lineItemDbLoader.loadByCourseId(ctx.getCourseId());
		
			QuestPathUtil qpUtil = new QuestPathUtil();
			List<QuestPathItem> itemList = qpUtil.buildInitialList(ctx, children, lineitems);
	
		//Create Loaders for Availability Rules, Criteria and Outcome
		//These loaders will allow us to capture Adaptive Release Information
			AvailabilityRuleDbLoader avRuleLoader = AvailabilityRuleDbLoader.Default.getInstance();
			AvailabilityCriteriaDbLoader avCriLoader = AvailabilityCriteriaDbLoader.Default.getInstance();
			OutcomeDefinitionDbLoader defLoad = OutcomeDefinitionDbLoader.Default.getInstance();				
			//Load ADAPTIVE RELEASE rules
			List<AvailabilityRule> rules = avRuleLoader.loadByCourseId(courseID);
			List<QuestRule> questRules = qpUtil.buildQuestRules(rules, avCriLoader, defLoad);
			
			itemList = qpUtil.setParentChildList(itemList, questRules);
			itemList = qpUtil.setInitialFinal(itemList);
			itemList = qpUtil.removeNonAdaptiveReleaseContent(itemList);
			itemList = qpUtil.setGradableQuestPathItemStatus(itemList, questRules);
			itemList = qpUtil.setLockOrUnlocked(itemList, questRules);
			
			Processor proc = new Processor();
			List<QuestPath> qPaths = proc.buildQuests(itemList);
%>
<h3 class='qpHdr1'>AVAILABLE QUEST PATHS</h3>
<%
if (!isUserAnInstructor) {
 for(QuestPath quest : qPaths) { 
  quest = qpUtil.setQuest(quest); %>
<h3 class="qpHdr2"><%=quest.getQuestName() %>
<%if (quest.getAttemptedQuests().size() == 0 
   && quest.getUnlockedQuests().size() == 0 
   && quest.getLockedItems().size() == 0 
   && quest.getLockedQuests().size() == 0) {%>
 <%=" COMPLETED" %>  
 <%} %>
</h3>
<table border="1" class="qp">
<tr>
<th class="qp">Passed</th>
<th class="qp">Attempted</th>
<th class="qp">Unlocked</th>
<th class="qp">Locked</th>
</tr>
<tr>
<td class="qp">
<%for (Integer i : quest.getPassedQuests()) { %>
<img src="<%=imagePath %>passed2.jpg" title="Assignment - <%=quest.getQuestPathItems().get(i).getName() + 
" Score - " + quest.getQuestPathItems().get(i).getPointsEarned() + "/" + quest.getQuestPathItems().get(i).getPointsPossible() + 
" ( " + quest.getQuestPathItems().get(i).getPercentFormatted() + "%) " 
%>
" class="imgC"/><br />XP <%=quest.getQuestPathItems().get(i).getPointsPossible()%><br />	
<% }%>
<%for (Integer i : quest.getRewardItems()) { %>
<img src="<%=imagePath %>reward.jpg" title="Reward - <%=quest.getQuestPathItems().get(i).getName() %>
" class="imgC"/><br /><%=quest.getQuestPathItems().get(i).getName()%><br />	
<% }%>

</td>
<td class="qp">
<%for (Integer i : quest.getAttemptedQuests()) { %>
<a title='CP1' href="../../execute/uploadAssignment?content_id=<%=quest.getQuestPathItems().get(i).getContentId().getExternalString()%>&course_id=<%=ctx.getCourseId().toExternalString()%>&assign_group_id=&mode=view">
<img src="<%=imagePath %>error.jpg" title="Assignment - <%=quest.getQuestPathItems().get(i).getName() + 
" Score - " + quest.getQuestPathItems().get(i).getPointsEarned() + "/" + quest.getQuestPathItems().get(i).getPointsPossible() + 
" ( " + quest.getQuestPathItems().get(i).getPercentFormatted()  + "%) " + 
quest.getQuestPathItems().get(i).getCompleteRule() %>
" class="imgC"/></a><br />XP <%=quest.getQuestPathItems().get(i).getPointsPossible()%><br />	
<% }%>
</td>
<td class="qp">
<%for (Integer i : quest.getUnlockedQuests()) { %>
<a title='CP1' href="../../execute/uploadAssignment?content_id=<%=quest.getQuestPathItems().get(i).getContentId().getExternalString()%>&course_id=<%=ctx.getCourseId().toExternalString()%>&assign_group_id=&mode=view">
<img src="<%=imagePath %>unlocked.jpg" title="Assignment - <%=quest.getQuestPathItems().get(i).getName() + 
" Score - " + quest.getQuestPathItems().get(i).getPointsEarned() + "/" + quest.getQuestPathItems().get(i).getPointsPossible() + 
" ( " + quest.getQuestPathItems().get(i).getPercentFormatted() + "%) " + 
quest.getQuestPathItems().get(i).getCompleteRule() %>
" class="imgC"/></a><br />XP <%=quest.getQuestPathItems().get(i).getPointsPossible()%><br />	
<% }%>
</td>
<td class="qp">
<%for (Integer i : quest.getLockedQuests()) { %>
<img src="<%=imagePath %>locked.jpg" title="Assignment - <%=quest.getQuestPathItems().get(i).getName() + 
" Score - " + quest.getQuestPathItems().get(i).getPointsEarned() + "/" + quest.getQuestPathItems().get(i).getPointsPossible() + 
" ( " + quest.getQuestPathItems().get(i).getPercentFormatted()  + "%) " + 
quest.getQuestPathItems().get(i).getUnlockRule()%>
" class="imgC"/><br />XP <%=quest.getQuestPathItems().get(i).getPointsPossible()%><br />	
<% }%>
<%for (Integer i : quest.getLockedItems()) { %>
<img src="<%=imagePath %>locked-reward.jpg" title="Reward - <%=quest.getQuestPathItems().get(i).getName()  + quest.getQuestPathItems().get(i).getUnlockRule()%>
" class="imgC"/><br /><%=quest.getQuestPathItems().get(i).getName()%><br />	
<% }%>
</td>
</tr>
</table>
<% } %>
<br /> <label>Hover over Quest Item to see associated Assignment Information</label> 
<% } else {%>
YOU HAVE ADDED QUESTPATH BLOCK FOR STUDENTS TO VIEW
<%} %>
</div>
</body>
</html>
</bbData:context>