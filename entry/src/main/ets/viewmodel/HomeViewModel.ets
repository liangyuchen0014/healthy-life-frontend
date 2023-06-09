/*
 * Copyright (c) 2022 Huawei Device Co., Ltd.
 * Licensed under the Apache License,Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import { DEFAULT_100 } from '../common/constants/CommonConstants';
import { isReachNewAchievement, ACHIEVEMENT_LEVEL_KEY } from '../model/AchieveModel';
import DatabaseApi from '../model/DatabaseModel';
import { TaskMapById, ITaskItem, ACHIEVEMENT_LEVEL_LIST } from '../model/TaskInitList';
import TaskInfo from '../common/bean/TaskInfo';
import DayInfo from '../common/bean/DayInfo';
import { dateToStr, weekDateFormat } from '../common/utils/Utils';
import { TaskInfoTableApi, TaskInfoTable } from '../common/database/tables/TaskInfoTable';
import { DayInfoTable } from '../common/database/tables/DayInfoTable';
import { GlobalInfoTable } from '../common/database/tables/GlobalInfoTable';
import { WeekDateModel, initializeOnStartUp, getPreviousWeek, WEEK_DAY_NUM } from '../model/WeekCalendarModel';
import { Logger } from '../common/utils/log/Logger';
import http from '@ohos.net.http';
let httpRequest = http.createHttp();

@Observed
export class HomeStore {
  public currentDate: Date;
  public dateArr: Array<WeekDateModel> = []; // data source list
  public selectedDay: number; // selected day of on week
  public showDate: number;
  public dateTitle: string ;
  public selectedDayInfo: WeekDateModel ; // task info on selected day
  dayInfoApi = new DayInfoTable();
  databaseApi = new DatabaseApi();
  taskInfoTableApi = new TaskInfoTable();
  globalInfoApi = new GlobalInfoTable();

  constructor(currentDate: Date) {
    this.currentDate = currentDate;
    this.showDate = currentDate.getTime();
    this.dateTitle = weekDateFormat(currentDate.getTime());
    this.selectedDay = (new Date().getDay() + WEEK_DAY_NUM - 1) % WEEK_DAY_NUM;
  }

  public initData() {
    let [initArr, dateArr] = initializeOnStartUp(this.currentDate);
    this.dateArr = initArr;
    Logger.info('this.currentDate', this.currentDate.toDateString());
    Logger.info('initWeekData dateArr', JSON.stringify(dateArr))
    // get data form db
    try {
      this.dayInfoApi.getRdbStore(() => {
        this.databaseApi.query(dateToStr(new Date()), (taskList, dayInfo) => {
          Logger.info('Current Day Task Info: ', JSON.stringify(taskList));
          this.dayInfoApi.queryList(dateArr, (res: DayInfo[]) => {
            let tempList = res.concat(dayInfo);
            let currentIndex = 0;
            Logger.info('initDayInfoList: ', JSON.stringify(res));
            for (let i = 0; i < this.dateArr.length; i++) {
              let tempDayInfo = tempList.find((item) => item.date == this.dateArr[i].dateStr) || {
                date: this.dateArr[i].dateStr,
                finTaskNum: 0,
                targetTaskNum: 0
              };
              initArr[i].dayInfo = tempDayInfo;
              initArr[i].taskList = taskList;
              if (this.dateArr[i].dateStr == dateToStr(new Date(this.showDate))) {
                // get tasks of showDate
                currentIndex = i;
              }
            }
            this.dateArr = initArr;
            setTimeout(() => {
              this.setSelectedShowDate(this.showDate);
            }, 0)
          })
        })
      })
    } catch (err) {
      Logger.error('err: ', err);
    }
  }

  public getPreWeekData(date: Date) {
    let [initArr, dateArr] = getPreviousWeek(date);
    // get data form db
    this.dayInfoApi.queryList(dateArr, (res: DayInfo[]) => {
      Logger.info('getPreWeekData->DayInfoList: ', JSON.stringify(res));
      if (res.length > 0) {
        for (let i = 0; i < initArr.length; i++) {
          let dayInfo = res.find((item) => item.date == initArr[i].dateStr) || null;
          initArr[i].dayInfo = dayInfo;
        }
      }
      this.dateArr = initArr.concat(...this.dateArr);
    })
  }

  // check is current day
  public checkCurrentDay(): boolean {
    return dateToStr(new Date()) == this.selectedDayInfo?.dateStr;
  }

  public updateSelectedDayInfo(selectedDayInfo: WeekDateModel) {
    Logger.debug('updateSelectedDayInfo', JSON.stringify(selectedDayInfo));
    if (selectedDayInfo.taskList?.length === 0) {
      // get data form db
      TaskInfoTableApi.getRdbStore(() => {
        TaskInfoTableApi.query(selectedDayInfo.dateStr, true, (res) => {
          Logger.info('Selected TaskInfoList: ', JSON.stringify(res));
          selectedDayInfo.taskList = res;
          this.dateArr = this.dateArr.map((item: WeekDateModel) =>
            item.dateStr == selectedDayInfo.dateStr ? { ...item, taskList: res } : item);
            this.selectedDayInfo = { ...selectedDayInfo };
        });
      })
    } else {
      this.selectedDayInfo = { ...selectedDayInfo };
    }
    Logger.info("selectedDayTaskInfo: ", JSON.stringify(selectedDayInfo.taskList));
  }

  public updateTaskInfoList(editedTaskInfo: ITaskItem) {
    if (editedTaskInfo?.taskID) {
      // edited task
      const {taskID, targetValue, isAlarm, frequency, startTime, endTime, isOpen } = editedTaskInfo;
      let task: TaskInfo = {
        isOpen,
        id: 0,
        date: dateToStr(new Date()),
        isDone: true,
        taskID,
        targetValue,
        isAlarm,
        frequency,
        startTime,
        endTime,
        finValue: targetValue
      }
      this.dateArr = this.dateArr.map((item: WeekDateModel) => {
        if (task.date == item.dateStr) {
          Logger.info('item', JSON.stringify(item));
          let taskList: TaskInfo[] = item.taskList;
          const dayInfo: DayInfo = item.dayInfo;
          if (editedTaskInfo.isOpen) {
            // add task
            taskList = taskList.filter((item) => item.taskID != taskID)
              .concat(task)
              .sort((a, b) => a.taskID - b.taskID);
            dayInfo.finTaskNum += 1;
          } else {
            // delete task
            let taskIndex = taskList.findIndex((item) => item.taskID == taskID);
            Logger.info('taskList[taskIndex]', JSON.stringify(taskList[taskIndex]));
            if (taskList[taskIndex]?.isDone) {
              dayInfo.finTaskNum -= 1;
            }
            taskList = taskList.filter((item) => item.taskID != taskID);
          }
          dayInfo.targetTaskNum = taskList.length;
          if (dayInfo.finTaskNum > dayInfo.targetTaskNum) {
            dayInfo.finTaskNum = dayInfo.targetTaskNum;
          }
          this.dayInfoApi.updateData(dayInfo, () => {
          });
          Logger.debug("tempDayInfo", JSON.stringify(dayInfo));
          let currentDayInfo = { ...item, taskList, dayInfo };
          if (this.checkCurrentDay()) {
            this.selectedDayInfo = currentDayInfo;
          }
          return currentDayInfo;
        }
        return item;
      }).slice(0);
    }
  }

  public setSelectedShowDate(showDateTime: number) {
    if (showDateTime > new Date().getTime()) {
      return;
    }
    this.showDate = showDateTime;
    this.dateTitle = weekDateFormat(this.showDate);
    let selectedInfo = this.dateArr.find((item: WeekDateModel) => item.dateStr == dateToStr(new Date(showDateTime)));
    if (selectedInfo) {
      this.updateSelectedDayInfo({ ...selectedInfo });
    }
    Logger.info('dateTitle', this.dateTitle);
  }

  public getDonePercent(): string {
    let dayInfo = this.selectedDayInfo?.dayInfo;
    Logger.debug("dayInfo", JSON.stringify(dayInfo));
    if (dayInfo && (dayInfo?.finTaskNum || 0) > 0) {
      if (dayInfo.finTaskNum > dayInfo.targetTaskNum) {
        return `${DEFAULT_100}`;
      }
      return `${Math.ceil(dayInfo.finTaskNum / dayInfo.targetTaskNum * DEFAULT_100)}`;
    }
    return '0';
  }

  public getTaskListOfDay(): TaskInfo[] {
    Logger.info('getTaskListOfDay', JSON.stringify(this.selectedDayInfo));
    if (this.selectedDayInfo && this.selectedDayInfo.taskList.length > 0) {
      return this.selectedDayInfo.taskList;
    }
    return [];
  }

  public async taskClock(taskInfo: TaskInfo) {
    let taskItem = await this.newUpdateTask(taskInfo);
    let dateStr = this.selectedDayInfo?.dateStr;
    if (!taskItem) {
      return Promise.resolve({
        achievementLevel: 0,
        showAchievement: false
      });
    }

    this.selectedDayInfo.taskList = this.selectedDayInfo.taskList.map((item) => {
      return item.taskID == taskItem?.taskID ? taskItem : item;
    });
    let achievementLevel;
    if (taskItem.isDone) {
      let dayInfo = await this.updateDayInfo();
      if (dayInfo && dayInfo?.finTaskNum === dayInfo?.targetTaskNum) {
        achievementLevel = await this.updateAchievement(this.selectedDayInfo.dayInfo);
      }
    }
    this.dateArr = this.dateArr.map((item: WeekDateModel) => dateStr == item.dateStr ? this.selectedDayInfo : item);
    Logger.info('achievementLevel', `${achievementLevel}`);
    return Promise.resolve({
      achievementLevel: achievementLevel,
      showAchievement: ACHIEVEMENT_LEVEL_LIST.includes(achievementLevel)
    });
  }

  newUpdateTask(task: TaskInfo): Promise<TaskInfo> {
    return new Promise((resolve, reject) => {
      let {taskID, targetValue, finValue} = task;
      let updateTask = Object.assign({}, task);
      let step = TaskMapById[taskID].step;
      let hasExceed = updateTask.isDone;
      if (step === 0) {
        updateTask.isDone = true;
        updateTask.finValue = targetValue;
      } else {
        let value = Number(finValue) + step;
        updateTask.isDone = value >= Number(targetValue);
        updateTask.finValue = updateTask.isDone ? targetValue : `${value}`;
      }
      httpRequest.request("http://119.3.171.141:3000/task/update",
        {
          method: http.RequestMethod.POST,
          header: { 'Content-Type': 'application/json' },
          extraData: updateTask,
        }, (err, data) => {
        if (!err) {
          // data.result为http响应内容，可根据业务需要进行解析
          console.info('Result:' + data.result);
          console.info('code:' + data.responseCode);
          // data.header为http响应头，可根据业务需要进行解析
          console.info('header:' + JSON.stringify(data.header));
          console.info('cookies:' + data.cookies); // 8+
          resolve(updateTask);
        } else {
          console.info('error:' + JSON.stringify(err));
          // 该请求不再使用，调用destroy方法主动销毁。
          httpRequest.destroy();
          reject(data.result);
        }
      }
      )
    })
  }

  updateTask(task: TaskInfo): Promise<TaskInfo> {
    return new Promise((resolve, reject) => {
      let {taskID, targetValue, finValue} = task;
      let updateTask = Object.assign({}, task);
      let step = TaskMapById[taskID].step;
      let hasExceed = updateTask.isDone;
      if (step === 0) {
        updateTask.isDone = true;
        updateTask.finValue = targetValue;
      } else {
        let value = Number(finValue) + step;
        updateTask.isDone = value >= Number(targetValue);
        updateTask.finValue = updateTask.isDone ? targetValue : `${value}`;
      }
      TaskInfoTableApi.updateDataByDate(updateTask, (res) => {
        if (!res || hasExceed) {
          Logger.error('taskClock-updateTask', res);
          reject(res);
        }
        resolve(updateTask);
      })
    })
  }

  updateDayInfo(): Promise<DayInfo> {
    let dayInfo: DayInfo = this.selectedDayInfo.dayInfo;
    dayInfo.finTaskNum += 1;
    dayInfo.targetTaskNum = this.selectedDayInfo.taskList.length;
    return new Promise((resolve, reject) => {
      this.dayInfoApi.updateData(dayInfo, (res) => {
        if (!res) {
          Logger.error('taskClock-updateDayInfo', res);
          reject(res);
        }
        Logger.info('taskClock-updateDayInfo', JSON.stringify(dayInfo));
        // 同步界面数据
        this.selectedDayInfo = { ...this.selectedDayInfo, dayInfo };
        resolve(dayInfo);
      });
    });
  }

  updateAchievement(dayInfo: DayInfo): Promise<number> {
    Logger.debug('taskClock-updateAchievement', JSON.stringify(dayInfo));
    return new Promise((resolve, reject) => {
      let preDay = new Date();
      preDay.setDate(preDay.getDate() - 1);
      preDay = new Date(preDay);
      let preDayStr = dateToStr(preDay);
      Logger.info('taskClock-updateAchievement-1', `${preDayStr}`);
      this.dayInfoApi.query(preDayStr, (res) => {
        Logger.info('taskClock-updateAchievement-2', JSON.stringify(res));
        let isReset = res?.length === 0 || res?.targetTaskNum > res?.finTaskNum;
        this.globalInfoApi.query((res) => {
          Logger.info('taskClock-globalInfoApi', JSON.stringify(res));
          let achievementInfo = res;
            isReset ? (achievementInfo.checkInDays = 1) : (achievementInfo.checkInDays += 1);
          let isNewAchieve = isReachNewAchievement(achievementInfo);
          if (isNewAchieve) {
            AppStorage.SetOrCreate(ACHIEVEMENT_LEVEL_KEY, achievementInfo.checkInDays);
            achievementInfo.achievements = achievementInfo.achievements + ',' + achievementInfo.checkInDays;
          }
          this.globalInfoApi.updateData(achievementInfo, (res) => {
            if (!res) {
              Logger.error('taskClock-updateAchievement', res);
              reject(res);
            }
            Logger.debug('taskClock-updateAchievement', achievementInfo);
              isNewAchieve ? resolve(achievementInfo.checkInDays) : resolve(0);
          });
        });
      })
    });
  }
}