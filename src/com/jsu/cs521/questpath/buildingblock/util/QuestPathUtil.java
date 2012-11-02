package com.jsu.cs521.questpath.buildingblock.util;

import java.util.ArrayList;
import java.util.List;

import blackboard.data.content.Content;
import blackboard.data.content.avlrule.AvailabilityCriteria;
import blackboard.data.content.avlrule.AvailabilityRule;
import blackboard.data.content.avlrule.GradeRangeCriteria;
import blackboard.data.gradebook.Lineitem;
import blackboard.data.gradebook.Score;
import blackboard.data.gradebook.impl.OutcomeDefinition;
import blackboard.persist.KeyNotFoundException;
import blackboard.persist.PersistenceException;
import blackboard.persist.content.avlrule.AvailabilityCriteriaDbLoader;
import blackboard.persist.gradebook.impl.OutcomeDefinitionDbLoader;
import blackboard.platform.context.Context;

import com.jsu.cs521.questpath.buildingblock.object.QuestPath;
import com.jsu.cs521.questpath.buildingblock.object.QuestPathItem;
import com.jsu.cs521.questpath.buildingblock.object.QuestRule;
import com.jsu.cs521.questpath.buildingblock.object.RuleCriteria;

public class QuestPathUtil {

	public List<QuestPathItem> removeNonAdaptiveReleaseContent(List<QuestPathItem> allItems) {
		List<QuestPathItem> finalList = new ArrayList<QuestPathItem>();
		for (QuestPathItem qPI : allItems) {
			if (qPI.getChildContent().size() > 0 || qPI.getParentContent().size() > 0) 
			{
				finalList.add(qPI);
			}
		}
		return finalList;
	}

	public List<QuestPathItem> setInitialFinal(List<QuestPathItem> allItems) {
		for (QuestPathItem qPI : allItems) {
			if (qPI.getChildContent().size() > 0 && qPI.getParentContent().size() == 0) 
			{
				qPI.setFirstQuestItem(true);
			}
			if (qPI.getChildContent().size() == 0 && qPI.getParentContent().size() > 0) 
			{
				qPI.setLastQuestItem(true);
			}
		}
		return allItems;
	}

	public List<QuestPathItem> setParentChildList(List<QuestPathItem> allItems, List<QuestRule> allRules) {
		for (QuestPathItem item : allItems) {
			for (QuestRule rule : allRules) {
				if (rule.getContentId().equals(item.getContentId())) {
					for (RuleCriteria crit : rule.getCriterias()) {
						item.getParentContent().add(crit.getParentContent());
						for(QuestPathItem item2 : allItems) {
							if(item2.getName().equals(crit.getParentContent())) {
								item2.getChildContent().add(item.getName());
							}
						}
					}
				}

			}
		}
		return allItems;
	}

	public List<QuestPathItem> buildInitialList(Context context, List<Content> contentItems, List<Lineitem> lineitems) {
		List<QuestPathItem> initialList = new ArrayList<QuestPathItem>();
		for (Content c : contentItems) {
			QuestPathItem newQP = new QuestPathItem();
			newQP.setName(c.getTitle());
			newQP.setContentId(c.getId());
			for(Lineitem li : lineitems) {
				if (li.getName().equals(newQP.getName())) {
					newQP.setGradable(true);
					if (li.getType().equals("Assignment") || li.getType().equals("Test")) {
						newQP.setPointsPossible(li.getPointsPossible());
						for (Score score : li.getScores()) {
							if (score.getCourseMembershipId().equals(context.getCourseMembership().getId())) {
								if (score.getOutcome().getScore() > newQP.getPointsEarned()) {
									newQP.setPointsEarned(score.getOutcome().getScore());
								}
							}
						}
						if (newQP.getPointsPossible() > 0) {
							newQP.setPercentageEarned(newQP.getPointsEarned()/newQP.getPointsPossible() * 100);
						}
					}
				}
			}
			initialList.add(newQP);
		}
		return initialList;
	}

	public List<QuestRule> buildQuestRules(List<AvailabilityRule> rules, AvailabilityCriteriaDbLoader avCriLoader, OutcomeDefinitionDbLoader defLoad ) throws KeyNotFoundException, PersistenceException {
		List<QuestRule> questRules = new ArrayList<QuestRule>();
		for(AvailabilityRule rule : rules) {
			boolean load = false;
			QuestRule questRule = new QuestRule();
			List<AvailabilityCriteria> criterias = avCriLoader.loadByRuleId(rule.getId());
			questRule.setContentId(rule.getContentId());
			questRule.setRuleId(rule.getId());
			for (AvailabilityCriteria criteria : criterias) {
				RuleCriteria ruleCrit = new RuleCriteria();
				if(criteria.getRuleType().equals(AvailabilityCriteria.RuleType.GRADE_RANGE)) {
					GradeRangeCriteria gcc = (GradeRangeCriteria) criteria;
					ruleCrit.setGradeRange(true);
					if(gcc.getMaxScore() != null ) {ruleCrit.setMaxScore(gcc.getMaxScore());}
					if(gcc.getMinScore() != null ) {ruleCrit.setMinScore(gcc.getMinScore());}
					OutcomeDefinition definition = defLoad.loadById(gcc.getOutcomeDefinitionId());
					ruleCrit.setParentContent(definition.getTitle());
					load = true;
					questRule.getCriterias().add(ruleCrit);
				}
				if(criteria.getRuleType().equals(AvailabilityCriteria.RuleType.GRADE_RANGE_PERCENT)) {
					GradeRangeCriteria gcc = (GradeRangeCriteria) criteria;
					ruleCrit.setGradePercent(true);
					if(gcc.getMaxScore() != null ) {ruleCrit.setMaxScore(gcc.getMaxScore());}
					if(gcc.getMinScore() != null ) {ruleCrit.setMinScore(gcc.getMinScore());}
					OutcomeDefinition definition = defLoad.loadById(gcc.getOutcomeDefinitionId());
					ruleCrit.setParentContent(definition.getTitle());
					load = true;
					questRule.getCriterias().add(ruleCrit);
				}
			}
			if (load) {
				questRules.add(questRule);
			}
		}
		return questRules;
	}

	//	public List<QuestPathItem> setQuestItemRule(List<QuestPathItem> allItems, List<QuestRule> rules) {
	//		for (QuestRule rule : rules) {
	//			for (QuestPathItem item : allItems) {
	//				if (rule.getContentId().equals(item.getContentId())) {
	//					item.setCriteria(rule.getCriterias());
	//				}
	//			}	
	//		}	
	//		//TODO Loop through Quest Items and set Child Parent Relationships
	//		return this.removeNonAdaptiveReleaseContent(allItems);
	//	}

	public List<QuestPathItem> setGradableQuestPathItemStatus(List<QuestPathItem> items, List<QuestRule> rules) {
		for (QuestPathItem item : items) {
			boolean passed = false;
			boolean attempted = false;
			if (item.isGradable()) {
				for(QuestRule rule : rules) {
					for (RuleCriteria ruleC : rule.getCriterias()) {
						if(ruleC.getParentContent().equals(item.getName())) {
							if (ruleC.isGradePercent()) {
								if (item.getPointsEarned() > 0 && item.getPercentageEarned() < ruleC.getMinScore()) {
									attempted = true;
								}
								if (item.getPercentageEarned() >= ruleC.getMinScore()) {
									passed = true;
								}
							}
							if (ruleC.isGradeRange()) {
								if (item.getPointsEarned() > 0 &&  item.getPointsEarned() < ruleC.getMinScore()) {
									attempted = true;
								}
								if (item.getPointsEarned() >= ruleC.getMinScore()) {
									passed = true;
								}
							}
						}
					}
				}
				if(attempted) {
					item.setAttempted(true);
				} 
				else 
				{
					if(passed) {
						item.setPassed(true);
					}
				}
			}
		}
		return items;
	}

	public List<QuestPathItem> setLockOrUnlocked(List<QuestPathItem> items, List<QuestRule> rules) {
		//TODO
		/*
		 * See if Item associated QuestPathItems are passed or attempted
		 * If all passed and not attempted - set to unlocked
		 * If attempted and passed exists - set to locked
		 * If not attempted and not passed - set to locked
		 */
		for (QuestPathItem item : items) {
			boolean locked = false;
			boolean unlocked = false;
			if (item.getParentContent().size() > 0) {
				for(QuestRule rule : rules) {
					if (rule.getContentId().equals(item.getContentId())) {
						for (RuleCriteria ruleCrit : rule.getCriterias()) {
							for (QuestPathItem item2 : items) {
								if (ruleCrit.getParentContent().equals(item2.getName())) {
									if (item2.isPassed()) {
										unlocked = true;
									}
									else {
										locked = true;
									}
								}
							}
						}

					}
				}
			}
			else 
			{
				unlocked = true;
			}
			if(locked) {
				item.setLocked(true);
			} 
			else 
			{
				if(unlocked) {
					item.setUnLocked(true);
				}
			}
		}
		return items;
	}
	
	public QuestPath setQuest(QuestPath qp) {
		for (QuestPathItem item : qp.getQuestPathItems()) {
			if (item.isUnLocked() && item.isPassed()) {
				qp.getPassedQuests().add(qp.getQuestPathItems().indexOf(item));
			}
			else if (item.isUnLocked() && !item.isGradable()) {
				qp.getRewardItems().add(qp.getQuestPathItems().indexOf(item));
			}
			else if (item.isAttempted() && item.isUnLocked()) {
				qp.getAttemptedQuests().add(qp.getQuestPathItems().indexOf(item));
			}
			else if (item.isUnLocked()) {
				qp.getUnlockedQuests().add(qp.getQuestPathItems().indexOf(item));
			}
			else if (item.isGradable() && item.isLocked()){
				qp.getLockedQuests().add(qp.getQuestPathItems().indexOf(item));
			}
			else {
				qp.getLockedItems().add(qp.getQuestPathItems().indexOf(item));
			}
			
		}
		return qp;
	}

}
