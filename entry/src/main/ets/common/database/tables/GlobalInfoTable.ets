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
import GlobalInfo from '../../bean/GlobalInfo';
import { GLOBAL_INFO } from '../../constants/CommonConstants';
import { Logger } from '../../../common/utils/log/Logger';
import http from '@ohos.net.http';

let httpRequest = http.createHttp();

export class GlobalInfoTable {
    private globalInfoTable = new Rdb(GLOBAL_INFO.tableName, GLOBAL_INFO.sqlCreate, GLOBAL_INFO.columns);

    constructor(callback = () => {}) {
        this.globalInfoTable.getRdbStore(callback);
    }

    /* Init */
    getRdbStore(callback = () => {}) {
        this.globalInfoTable.getRdbStore(callback);
    }

    /**
     * insert globalInfo
     *
     * @param globalInfo
     * @param callback
     */
/*    insertData(globalInfo: GlobalInfo, callback) {
        const valueBucket = generateBucket(globalInfo);
        this.globalInfoTable.insertData(valueBucket, callback);
        Logger.info('GlobalInfoTable', 'Insert globalInfo finished.');
    }*/

    insertData(globalInfo: GlobalInfo, callback){
        if (!callback || typeof callback == 'undefined' || callback == undefined) {
            Logger.error('Rdb', 'insertData() has no callback!');
            return;
        }
        httpRequest.request("http://119.3.171.141:3000/globalinfo/add",
            {
                method: http.RequestMethod.POST,
                header: { 'Content-Type': 'application/json' },
                extraData: globalInfo,
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
     * update globalInfo
     *
     * @param globalInfo
     * @param callback
     */
/*    updateData(globalInfo: GlobalInfo, callback) {
        const valueBucket = generateBucket(globalInfo);
        let predicates = new data_rdb.RdbPredicates(GLOBAL_INFO.tableName);
        predicates.equalTo('id', 0);
        this.globalInfoTable.updateData(predicates, valueBucket, callback);
        Logger.verbose('GlobalInfoTable', 'Update globalInfo finished.');
    }*/
    updateData(globalInfo: GlobalInfo, callback) {
        if (!callback || typeof callback == 'undefined' || callback == undefined) {
            Logger.error('Rdb', 'insertData() has no callback!');
            return;
        }
        httpRequest.request("http://119.3.171.141:3000/globalinfo/update",
            {
                method: http.RequestMethod.POST,
                header: { 'Content-Type': 'application/json' },
                extraData: globalInfo,
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
     * query globalInfo
     *
     * @param callback
     */
    /*query(callback) {
        let predicates = new data_rdb.RdbPredicates(GLOBAL_INFO.tableName);
        predicates.equalTo('id', 0);
        this.globalInfoTable.query(predicates, function(resultSet) {
            let count = resultSet.rowCount;
            if (count === 0) {
                Logger.info('GlobalInfoTable','query no results!');
                callback([]);
            } else {
                let result = new GlobalInfo('', '', 0, '');
                resultSet.goToFirstRow();
                result.firstDate = resultSet.getString(resultSet.getColumnIndex('firstDate'));
                result.lastDate = resultSet.getString(resultSet.getColumnIndex('lastDate'));
                result.checkInDays = resultSet.getDouble(resultSet.getColumnIndex('checkInDays'));
                result.achievements = resultSet.getString(resultSet.getColumnIndex('achievements'));
                callback(result);
            }
            return;
        });
    }*/
    query( callback){
        httpRequest.request("http://119.3.171.141:3000/globalinfo/query",
            {
                method: http.RequestMethod.GET,
            }, (err, data) => {
                if (!err) {
                    console.info('全局信息查询结果:' + data.result);
                    console.info('code:' + data.responseCode);
                    let a=JSON.parse(data.result as string);
                    let result = new GlobalInfo('', '', 0, '');
                    result.firstDate=a.firstDate
                    result.lastDate=a.lastDate
                    result.checkInDays=a.checkInDays
                    result.achievements=a.achievements
                    console.info(result.firstDate.toString())
                    console.info(result.lastDate.toString())
                    console.info(result.checkInDays.toString())
                    console.info(result.achievements.toString())
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
}

function generateBucket(globalInfo: GlobalInfo) {
    let obj = {};
    GLOBAL_INFO.columns.forEach((item) => {
        if (item === 'id') {
            obj[item] = 0;
        } else {
            obj[item] = globalInfo[item];
        }
    });
    return obj;
}
