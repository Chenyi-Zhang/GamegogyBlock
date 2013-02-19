<%@page import="blackboard.base.*"%>
<%@page import="blackboard.data.course.*"%> 				<!-- for reading data -->
<%@page import="blackboard.data.user.*"%> 					<!-- for reading data -->
<%@page import="blackboard.persist.*"%> 					<!-- for writing data -->
<%@page import="blackboard.persist.course.*"%> 				<!-- for writing data -->
<%@page import="blackboard.platform.gradebook2.*"%>
<%@page import="blackboard.platform.gradebook2.impl.*"%>
<%@page import="java.util.*"%> 								<!-- for utilities -->
<%@page import="blackboard.platform.plugin.PlugInUtil"%>	<!-- for utilities -->
<%@ taglib uri="/bbData" prefix="bbData"%> 					<!-- for tags -->
<%@ taglib uri="/bbNG" prefix="bbNG"%>

<%@page import="com.spvsoftwareproducts.blackboard.utils.B2Context"%>

<%
	String color_value = "";
	String [] level_values = new String[10];
	String jsConfigFormPath = PlugInUtil.getUri("dt", "leaderboardblock11", "js/config_form.js");
		
	// Create a new persistence object.  Don't save empty fields.
	B2Context b2Context = new B2Context(request);
	b2Context.setSaveEmptyValues(false);
	
	// Grab previously saved color value
	color_value = b2Context.getSetting(false, true, "color");
	
	// Grab previously saved level values
	for(int i = 0; i < 10; i++){
		level_values[i] = b2Context.getSetting(false, true, "Level_" + (i+1) + "_Points");
	}
	
%>

<bbNG:modulePage type="personalize" ctxId="ctx">
<bbNG:pageHeader>
	<bbNG:pageTitleBar title="Leaderboard Configuration"></bbNG:pageTitleBar>
</bbNG:pageHeader>

<!-- Body Content: Plotbands & Color Picker -->
<bbNG:form action="leaderboard_save.jsp" method="post" name="plotband_config_form" id="plotband_config_form" onSubmit="return validateForm()">
	<bbNG:dataCollection>
	
		<!-- Color Picker -->
		<bbNG:step title="Plotbands Color">
			<bbNG:dataElement>
				<bbNG:elementInstructions text="Choose a plotband color." />
				<bbNG:colorPicker name="color" initialColor="<%= color_value %>"/>
			</bbNG:dataElement>
		</bbNG:step>
		
			<%	
				// get the current user's information
				String sessionUserRole = ctx.getCourseMembership().getRoleAsString();
				boolean isUserAnInstructor = false;
				if (sessionUserRole.trim().toLowerCase().equals("instructor")) {
					isUserAnInstructor = true;
				}	
			%>
			
			<!-- Plotbands Configuration Form -->
			<% if (isUserAnInstructor) { %>
				<bbNG:step title="Plotbands Points">
					<bbNG:dataElement>
						<bbNG:elementInstructions text="Set point requirements for each level. The points are cumulative. If Level 1 is set for 100 points and Level 2 is set for 50 points, then it takes 150 points to reach Level 2." />
						<table>
							<!-- Fill up table with 10 levels.  Includes label & input field -->
							<% for(int i = 1; i <= 10; i++) { %>
								<tr id="Level_<%= i %>">
									<td>Level <%= i %> -</td>
									<td><input type="text" name="Level_<%= i %>_Points" size="3" value="<%=level_values[i-1]%>" onkeyup="checkForm()"/></td>
								</tr>
							<% } %>
						</table>
						<input id="popLevel_button" type="button" value="-" onclick="subtractLevel()" />
						<input id="pushLevel_button" type="button" value="+" onclick="addLevel()" />
						<input type="button" value="Reset" onclick="resetForm()" />
						<input type="button" value="Clear" onclick="clearForm()" />
						
						<!-- Javascript Form Logic //-->
						<script type="text/javascript" src="<%= jsConfigFormPath %>"></script>
					</bbNG:dataElement>
				</bbNG:step>
			<% } %>
		<bbNG:stepSubmit />
	</bbNG:dataCollection>
</bbNG:form>
</bbNG:modulePage>
