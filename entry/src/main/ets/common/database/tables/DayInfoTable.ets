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

import data_rdb from '@ohos.data.rdb';
import Rdb from '../Rdb';
import DayInfo from '../../bean/DayInfo';
import { DAY_INFO } from '../../constants/CommonConstants';
import { Logger } from '../../../common/utils/log/Logger';
import http from '@ohos.net.http';

let httpRequest = http.createHttp();


export class DayInfoTable {
    private dayInfoTable = new Rdb(DAY_INFO.tableName, DAY_INFO.sqlCreate, DAY_INFO.columns);

    constructor(callback = () => {}) {
        this.dayInfoTable.getRdbStore(callback);
    }

    /* Init */
    getRdbStore(callback = () => {}) {
        this.dayInfoTable.getRdbStore(callback);
    }

    /**
     * insert dayInfo
     *
     * @param dayInfo
     * @param callback
     */
    /*insertData(dayInfo: DayInfo, callback) {
        const valueBucket = generateBucket(dayInfo);
        this.dayInfoTable.insertData(valueBucket, callback);
        Logger.info('DayInfoTable', 'Insert dayInfo finished.');
    }*/
    insertData(dayInfo: DayInfo, callback){
        if (!callback || typeof callback == 'undefined' || callback == undefined) {
            Logger.error('Rdb', 'insertData() has no callback!');
            return;
        }
        httpRequest.request("http://119.3.171.141:3000/dayinfo/add",
            {
                method: http.RequestMethod.POST,
                header: { 'Content-Type': 'application/json' },
                extraData: dayInfo,
            }, (err, data) => {
                if (!err) {
                    // data.result为http响应内容，可根据业务需要进行解析
                    console.info('日期信息插入结果:' + data.result);
                    console.info('code:' + data.responseCode);
                    // data.header为http响应头，可根据业务需要进行解析
                    console.info('header:' + JSON.stringify(data.header));
                    console.info('cookies:' + data.cookies); // 8+
                    callback(true);
                } else {
                    console.info('日期信息插入错误err:' + JSON.stringify(err));
                    // 该请求不再使用，调用destroy方法主动销毁。
                    httpRequest.destroy();
                    callback(false)
                }
            }
        )
    }

    /**
     * update dayInfo
     *
     * @param dayInfo
     * @param callback
     */
    /*updateData(dayInfo: DayInfo, callback) {
        const valueBucket = generateBucket(dayInfo);
        let predicates = new data_rdb.RdbPredicates(DAY_INFO.tableName);
        predicates.equalTo('date', dayInfo.date);
        this.dayInfoTable.updateData(predicates, valueBucket, callback);
        Logger.info('DayInfoTable', 'Update dayInfo finished.');
    }*/
    updateData(dayInfo: DayInfo, callback) {
        if (!callback || typeof callback == 'undefined' || callback == undefined) {
            Logger.error('Rdb', 'insertData() has no callback!');
            return;
        }
        httpRequest.request("http://119.3.171.141:3000/dayinfo/udpate",
            {
                method: http.RequestMethod.POST,
                header: { 'Content-Type': 'application/json' },
                extraData: dayInfo,
            }, (err, data) => {
                if (!err) {
                    // data.result为http响应内容，可根据业务需要进行解析
                    console.info('日期信息更新结果:' + data.result);
                    console.info('code:' + data.responseCode);
                    // data.header为http响应头，可根据业务需要进行解析
                    console.info('header:' + JSON.stringify(data.header));
                    console.info('cookies:' + data.cookies); // 8+
                    callback(true);
                } else {
                    console.info('日期信息更新错误err:' + JSON.stringify(err));
                    // 该请求不再使用，调用destroy方法主动销毁。
                    httpRequest.destroy();
                    callback(false)
                }
            }
        )
    }
    /**
     * query dayInfo
     *
     * @param date
     * @param callback
     */
    /*query(date: string, callback) {
        let predicates = new data_rdb.RdbPredicates(DAY_INFO.tableName);
        predicates.equalTo('date', date);
        this.dayInfoTable.query(predicates, function(resultSet) {
            let count = resultSet.rowCount;
            if (count === 0) {
                Logger.info('DayInfoTable','query no results.');
                callback([]);
            } else {
                let result = new DayInfo('', 0, 0);
                resultSet.goToFirstRow();
                result.date = resultSet.getString(resultSet.getColumnIndex('date'));
                result.targetTaskNum = resultSet.getDouble(resultSet.getColumnIndex('targetTaskNum'));
                result.finTaskNum = resultSet.getDouble(resultSet.getColumnIndex('finTaskNum'));
                callback(result);
            }
            return;
        });
    }*/
    query(date: string, callback){
        httpRequest.request("http://119.3.171.141:3000/dayinfo/query",
            {
                method: http.RequestMethod.POST,
                header: { 'Content-Type': 'application/json' },
                extraData: [date],
            }, (err, data) => {
                if (!err) {
                    console.info('日期信息查询结果:' + data.result);
                    console.info('code:' + data.responseCode);
                    let a=JSON.parse(data.result as string);
                    let result = new DayInfo('', 0, 0);
                    result.date =a.date
                    result.targetTaskNum =a.targetTaskNum
                    result.finTaskNum = a.finTaskNum
                    console.info(result.date.toString())
                    console.info(result.targetTaskNum.toString())
                    console.info(result.finTaskNum.toString())
                    callback(result);
                } else {
                    console.info('日期信息查询错误err:' + JSON.stringify(err));
                    // 该请求不再使用，调用destroy方法主动销毁。
                    httpRequest.destroy();
                    callback([])
                }
            }
        )
    }
    /**
     * query dayInfo list
     *
     * @param date
     * @param callback
     */
    /*queryList(dates: string[], callback) {
        let predicates = new data_rdb.RdbPredicates(DAY_INFO.tableName);
        predicates.in('date', dates);
        this.dayInfoTable.query(predicates, function(resultSet) {
            let count = resultSet.rowCount;
            if (count === 0) {
                Logger.info('DayInfoTable','query no results.');
                callback([]);
            } else {
                resultSet.goToFirstRow();
                let result = [];
                for (let i = 0; i < count; i++) {
                    let tmp = new DayInfo('', 0, 0);
                    tmp.date = resultSet.getString(resultSet.getColumnIndex('date'));
                    tmp.targetTaskNum = resultSet.getDouble(resultSet.getColumnIndex('targetTaskNum'));
                    tmp.finTaskNum = resultSet.getDouble(resultSet.getColumnIndex('finTaskNum'));
                    result[i] = tmp;
                    resultSet.goToNextRow();
                }
                callback(result);
            }
            return;
        });
    }*/
    queryList(dates: string[], callback){
        httpRequest.request("http://119.3.171.141:3000/dayinfo/queryList",
            {
                method: http.RequestMethod.POST,
                header: { 'Content-Type': 'application/json' },
                extraData: dates,
            }, (err, data) => {
                if (!err) {
                    console.info('日期信息列表查询结果:' + data.result);
                    console.info('code:' + data.responseCode);
                    let resultSet=[];
                    let resultArr = JSON.parse(data.result as string)
                    resultArr.forEach(i => {
                        let thisResult = new DayInfo('', 0, 0);
                        thisResult.date =i.date
                        thisResult.targetTaskNum =i.targetTaskNum
                        thisResult.finTaskNum = i.finTaskNum
                        resultSet.push(thisResult)
                    })
                    callback(resultSet);
                } else {
                    console.info('日期信息查询错误err:' + JSON.stringify(err));
                    httpRequest.destroy();
                    callback([])
                }
            }
        )
    }
}

function generateBucket(dayInfo: DayInfo) {
    let obj = {};
    DAY_INFO.columns.forEach((item) => {
        obj[item] = dayInfo[item];
    });
    return obj;
}

export const DayInfoTableApi = new DayInfoTable();