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

import { DayInfoTable } from '../common/database/tables/DayInfoTable';
import { GlobalInfoTable } from '../common/database/tables/GlobalInfoTable';
import { TaskInfoTable } from '../common/database/tables/TaskInfoTable';
import DayInfo from '../common/bean/DayInfo';
import GlobalInfo from '../common/bean/GlobalInfo';
import TaskInfo from '../common/bean/TaskInfo';
import { GLOBAL_KEY, TASK_NUM } from '../common/constants/CommonConstants';
import { Logger } from '../common/utils/log/Logger';


export default class DatabaseModel {
    private dayInfoTable = new DayInfoTable();
    private globalInfoTable = new GlobalInfoTable();
    private taskInfoTable = new TaskInfoTable();

    constructor() {
        this.dayInfoTable.getRdbStore();
        this.globalInfoTable.getRdbStore();
        this.taskInfoTable.getRdbStore();
    }

    /**
     * Init when open the app
     *
     * @param date
     * @param callback
     */
    query(date: string, callback) {
        let result = [];
        let self = this;
        this.globalInfoTable.query(function(globalResult) {
            if (globalResult.length === 0) {  // if global information is not found, it is written
                let globalInfo = new GlobalInfo(date, date, 0, '');
                self.globalInfoTable.insertData(globalInfo, (isDone) => {
                    if (isDone) {
                        Logger.info('AppStart', 'Insert globalInfo success: ' + JSON.stringify(globalInfo));
                    }
                });
                self.insertGlobalTask(self);
                let dayInfo = new DayInfo(date, 0, 0);
                self.dayInfoTable.insertData(dayInfo, (isDone) => {
                    if (isDone) {
                        Logger.info('AppStart', 'Insert dayInfo success: ' + JSON.stringify(dayInfo));
                    }
                })
                self.insertTask(self, date);
                callback(result, dayInfo);
            } else {  // if global information is found, the task information for the day is queried
                let newGlobalInfo = globalResult;
                let preDate = globalResult.lastDate;
                newGlobalInfo.lastDate = date;
                self.globalInfoTable.updateData(newGlobalInfo, (isDone) => {
                    if (isDone) {
                        Logger.info('AppStart', 'update globalInfo success: ' + JSON.stringify(newGlobalInfo));
                    }
                });
                self.queryPreInfo(self, date, preDate, result, callback);
            }
        });
    }

    insertGlobalTask(self) {
        for (let i = 0; i < TASK_NUM; i++) {
            let tmp = new TaskInfo(0, GLOBAL_KEY, i + 1, '', false, '08: 00', '00: 00', '1,2,3,4,5,6,7', false, '');
            self.taskInfoTable.insertData(tmp, (isDone) => {
                if (isDone) {
                    Logger.info('AppStart', 'Insert taskGlobalInfo success: ' + JSON.stringify(tmp));
                }
            });
        }
    }

    insertTask(self, date) {
        for (let i = 0 ; i < TASK_NUM; i++) {
            let tmp = new TaskInfo(0, date, i + 1, '', false, '08: 00', '00: 00', '1,2,3,4,5,6,7', false, '');
            self.taskInfoTable.insertData(tmp, (isDone) => {
                if (isDone) {
                    Logger.info('AppStart', 'Insert taskInfo success: ' + JSON.stringify(tmp));
                }
            });
        }
    }

    queryPreInfo(self, date, preDate, result, callback) {
        self.taskInfoTable.query(date, false, (taskResult) => {  // query the task information for the day
            let dayInfo = new DayInfo(date, 0, 0);
            if (taskResult.length === 0) {  // if task information for the day is not found, the global task information is queried
                let curDate = new Date(preDate);
                curDate.setDate(curDate.getDate()+1);
                Logger.info('AppStart', 'insert data begin: ' + curDate.toDateString())
                let finDate = new Date(date);
                finDate.setDate(finDate.getDate()+1);
                Logger.info('AppStart', 'insert data end: ' + finDate.toDateString())
                self.taskInfoTable.query(GLOBAL_KEY, false, (globalTaskResult) => {
                    result = globalTaskResult;
                    dayInfo.targetTaskNum = self.calTaskNum(result);
                    self.insertPreInfo(curDate, finDate, result, dayInfo);
                })
            } else {
                let dayInfoList = self.calFinishNum(taskResult, result);
                dayInfo.targetTaskNum = dayInfoList[0];
                dayInfo.finTaskNum = dayInfoList[1];
            }
            callback(result, dayInfo);
        });
    }

    calTaskNum(result) {
        let taskNum = 0;
        for (let i = 0; i < TASK_NUM; i++) {
            if (result[i].isOpen) {
                taskNum += 1;
            }
        }
        return taskNum;
    }

    insertPreInfo(curDate, finDate, result, dayInfo) {
        while (curDate.toDateString() != finDate.toDateString()) {
            dayInfo.date = curDate.toDateString();
            this.dayInfoTable.insertData(dayInfo, (isDone) => {
                if (isDone) {
                    Logger.info('AppStart', 'insert dayInfo success: ' + JSON.stringify(dayInfo));
                }
            })
            for (let i = 0; i < TASK_NUM; i++) {
                let tmp = new TaskInfo(0, '', 0, '', false, '', '', '', false, '');
                tmp = result[i];
                tmp.date = curDate.toDateString();
                this.taskInfoTable.insertData(tmp, (isDone) => {
                    if (isDone) {
                        Logger.info('AppStart', 'insert taskInfo success: ' + JSON.stringify(tmp));
                    }
                })
            }
            curDate.setDate(curDate.getDate()+1);
        }
    }

    calFinishNum(taskResult, result) {
        let taskNum = 0;
        let finishNum = 0;
        for (let i = 0; i < TASK_NUM; i++) {
            if (taskResult[i].isOpen) {
                result.push(taskResult[i]);
                taskNum += 1;
                if (taskResult[i].isDone) {
                    finishNum += 1;
                }
            }
        }
        return [taskNum, finishNum];
    }
}