package com.jsu.cs521.questpath.buildingblock.object;

public class RuleCriteria {
	private boolean isGradeRange;
	private boolean isGradePercent;
	private float maxScore;
	private float minScore;
	private String parentContent;
	
	public RuleCriteria() {
		this.maxScore = 0.0f;
		this.minScore = 0.0f;
		this.isGradePercent = false;
		this.isGradeRange = false;
		this.parentContent = "";
	}
	
	public boolean isGradeRange() {
		return isGradeRange;
	}
	public void setGradeRange(boolean isGradeRange) {
		this.isGradeRange = isGradeRange;
	}
	public boolean isGradePercent() {
		return isGradePercent;
	}
	public void setGradePercent(boolean isGradePercent) {
		this.isGradePercent = isGradePercent;
	}
	public float getMaxScore() {
		return maxScore;
	}
	public void setMaxScore(float maxScore) {
		this.maxScore = maxScore;
	}
	public float getMinScore() {
		return minScore;
	}
	public void setMinScore(float minScore) {
		this.minScore = minScore;
	}
	public String getParentContent() {
		return parentContent;
	}
	public void setParentContent(String parentContent) {
		this.parentContent = parentContent;
	}
	
	

}
