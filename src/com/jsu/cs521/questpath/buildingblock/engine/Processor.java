package com.jsu.cs521.questpath.buildingblock.engine;

import java.util.ArrayList;
import java.util.List;

import com.jsu.cs521.questpath.buildingblock.object.QuestPath;
import com.jsu.cs521.questpath.buildingblock.object.QuestPathItem;

public class Processor {
	
	private int i = 1;

	public List<QuestPath> buildQuests(List<QuestPathItem> items) {
		List<QuestPathItem> tempListA = new ArrayList<QuestPathItem>();
		tempListA.addAll(items);
		List<QuestPathItem> tempListB = new ArrayList<QuestPathItem>();
		tempListB.addAll(items);
		List<QuestPath> paths = new ArrayList<QuestPath>();
		for (QuestPathItem item : items) {
			if (item.isFirstQuestItem()) {
				QuestPath newPath = new QuestPath();
				newPath.getQuestPathItems().add(item);
				newPath.getQuestItemNames().add(item.getName());
				newPath.setQuestName("QuestPath - " + i);
				tempListB.remove(item);
				i++;
				paths.add(newPath);
			}
		}
		tempListA.clear(); 
		tempListA.addAll(tempListB);
		boolean process = true;
		int prevSize = tempListA.size();
		while (tempListA.size() > 0 && process) {
			for (QuestPathItem item : tempListA) {
				for (QuestPath qp : paths) {
					for (String parentItem : item.getParentContent()) {
						if (qp.getQuestItemNames().contains(parentItem)) {
							qp.getQuestItemNames().add(item.getName());
							qp.getQuestPathItems().add(item);
							tempListB.remove(item);
							break;
						}
					}
				}
			}
			if (tempListB.size() == prevSize) {
				process = false;
			}
			tempListA.clear(); 
			tempListA.addAll(tempListB);
			prevSize = tempListA.size();
		}
			
				
		
		return paths;
	}
	
}
