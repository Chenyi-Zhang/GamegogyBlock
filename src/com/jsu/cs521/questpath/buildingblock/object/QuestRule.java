package com.jsu.cs521.questpath.buildingblock.object;

import java.util.ArrayList;
import java.util.List;

import blackboard.persist.Id;

public class QuestRule {
	private Id ruleId;
	private Id contentId;
	private List<RuleCriteria> criterias = new ArrayList<RuleCriteria>();
	
	public Id getRuleId() {
		return ruleId;
	}
	public void setRuleId(Id ruleId) {
		this.ruleId = ruleId;
	}
	public Id getContentId() {
		return contentId;
	}
	public void setContentId(Id contentId) {
		this.contentId = contentId;
	}
	public List<RuleCriteria> getCriterias() {
		return criterias;
	}
	public void setCriterias(List<RuleCriteria> criterias) {
		this.criterias = criterias;
	}
	@Override
	public String toString() {
		return "QuestRule [ruleId=" + ruleId + ", contentId=" + contentId
				+ ", criterias=" + criterias + "]";
	}
	
	
	

}
