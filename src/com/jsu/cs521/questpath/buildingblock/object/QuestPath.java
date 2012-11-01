package com.jsu.cs521.questpath.buildingblock.object;

import java.util.ArrayList;
import java.util.List;

public class QuestPath {
	private List<QuestPathItem> questPathItems = new ArrayList<QuestPathItem>();
	private String questName = "";
	private List<String> questItemNames = new ArrayList<String>();

	public List<QuestPathItem> getQuestPathItems() {
		return questPathItems;
	}

	public void setQuestPathItems(List<QuestPathItem> questPathItems) {
		this.questPathItems = questPathItems;
	}

	public String getQuestName() {
		return questName;
	}

	public void setQuestName(String questName) {
		this.questName = questName;
	}

	public List<String> getQuestItemNames() {
		return questItemNames;
	}

	public void setQuestItemNames(List<String> questItemNames) {
		this.questItemNames = questItemNames;
	}
	
	
	
	

}
