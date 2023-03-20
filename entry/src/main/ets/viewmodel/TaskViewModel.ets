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

/*
您好，这是Bing。我可以用中文和您交流。😊

这段代码是用TypeScript编写的，TypeScript是一种基于JavaScript的强类型编程语言¹。这个函数的原理是：

- 定义一个名为getAllTask的异步函数，它没有参数，返回一个Promise对象。
- 在Promise对象中，定义一个回调函数，它接受一个参数resolve，表示成功时的处理函数。
- 调用taskInfoTable.query方法，传入GLOBAL_KEY和true作为参数，以及一个匿名函数作为回调函数。
- 在匿名函数中，判断res是否存在且长度不为0，如果是，则调用resolve(res)将结果传递给Promise对象；否则，打印一条警告信息，并调用resolve(res ?? [])将空数组传递给Promise对象。
- 这样，当getAllTask函数被调用时，它会返回一个Promise对象，该对象在查询数据库后会被解决或拒绝。


好的，我来进一步讲解async和promise。

- async是一个关键字，它可以放在一个函数定义前面，表示这个函数是异步的，也就是说它会返回一个promise对象²⁵。
- promise是一种对象，它代表了一个异步操作的当前状态。异步操作可能还没有完成，但promise对象提供了一些方法来处理最终的成功或失败⁴。
- await是一个运算符，它可以放在一个promise对象前面，表示等待这个promise对象被解决或拒绝。如果promise对象被解决了，await运算符会返回解决值；如果promise对象被拒绝了，await运算符会抛出错误²⁵。
- async和await可以让我们用同步的方式写异步的代码，使得代码更加简洁和清晰³。

这个函数是这样被调用的：getAllTask().then(res => { let deepCopyData = JSON.stringify(this.taskList); deepCopyData = JSON.parse(deepCopyData); this.taskList = taskIndexDataInit(deepCopyData, res); })在这里面，res是getAllTask()中的什么？
在这里面，res是getAllTask()中的res，也就是taskInfoTable.query方法的回调函数的参数。它表示数据库查询的结果，可能是一个数组或者null。
可是在getAllTask中定义的返回值是return new Promise((resolve) => {...}，并不是res啊
是的，getAllTask()返回的是一个promise对象，但是这个promise对象会在数据库查询完成后被解决，并且传递res作为解决值。所以，当我们用.then方法来处理这个promise对象时，我们可以拿到res作为参数。
* promise可以传递任何值作为解决值，只要在调用resolve函数时传入这个值就可以了。例如，我们可以写一个这样的promise：

return new Promise((resolve) => { resolve(“Hello”); });

这个promise会被立即解决，并且传递"Hello"作为解决值。所以，我们可以用.then方法来获取这个值：

.then(value => { console.log(value); // Hello });
* */
import { TaskInfoTable } from '../common/database/tables/TaskInfoTable';
import { Logger } from '../common/utils/log/Logger';
import TaskInfo, { oneWeek } from '../common/bean/TaskInfo';
import {
    EVERYDAY,
    GLOBAL_KEY,
    TODAY,
    DRINK_STEP,
    DRINK_MAX_RANGE,
    EAT_APPLE_RANGE,
    TIMES_100
} from '../common/constants/CommonConstants';
import { TaskMapById, ITaskItem } from '../model/TaskInitList';
import { padTo2Digits } from '../common/utils/Utils';
import http from '@ohos.net.http';

let httpRequest = http.createHttp();
let task1: TaskInfo = {
    "id": 0,
    "taskID": 1,
    "isOpen": true,
    "date": "",
    "targetValue": "7:00",
    "isAlarm": true,
    "startTime": "",
    "endTime": ";",
    "frequency": "",
    "isDone": false,
    "finValue": ""
}

const taskInfoTable = new TaskInfoTable();

export const taskOriginData: ITaskItem[] = Object.keys(TaskMapById).map(item => {
    return TaskMapById[item];
})

/**
 * resolve: 表示成功时的处理函数
 * @description Get all task status
 * @return object[] Database query results
 */
export const getAllTask = async () => {
    return new Promise((resolve) => {
        taskInfoTable.query(GLOBAL_KEY, true, (res) => {
            if (res?.length === 0) {
                Logger.warn('queryTaskList', 'has no data!!');
                resolve(res ?? []);
            }
            resolve(res);
        })
    });
}

export const newGetAllTask = async () => {
    console.log('获取全部任务');
    return new Promise((resolve) => {
        httpRequest.request("http://119.3.171.141:3000/task/getAll",
            {
                method: http.RequestMethod.GET,
            }, (err, data) => {
                if (!err) {
                    // data.result为http响应内容，可根据业务需要进行解析
                    console.info('Result:' + data.result);
                    console.info('code:' + data.responseCode);
                    // data.header为http响应头，可根据业务需要进行解析
                    console.info('header:' + JSON.stringify(data.header));
                    console.info('cookies:' + data.cookies); // 8+
                    resolve(data.result);
                } else {
                    console.info('error:' + JSON.stringify(err));
                    // 该请求不再使用，调用destroy方法主动销毁。
                    httpRequest.destroy();
                }
            }
        )
    });
}

export const newAddTask = (params: TaskInfo) => {
    if (!params) {
        Logger.error('addTask', 'params is null!');
        return;
    }
    return new Promise((resolve, reject) => {
        httpRequest.request("http://119.3.171.141:3000/task/add",
            {
                method: http.RequestMethod.POST,
                header: { 'Content-Type': 'application/json' },
                extraData: params,
            }, (err, data) => {
                if (!err) {
                    // data.result为http响应内容，可根据业务需要进行解析
                    console.info('Result:' + data.result);
                    console.info('code:' + data.responseCode);
                    // data.header为http响应头，可根据业务需要进行解析
                    console.info('header:' + JSON.stringify(data.header));
                    console.info('cookies:' + data.cookies); // 8+
                    resolve(data.result);
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
/**
 * @param params:TaskInfo
 */
export const addTask = (params: TaskInfo) => {
    if (!params) {
        Logger.error('addTask', 'params is null!');
        return;
    }
    return new Promise((resolve, reject) => {
        taskInfoTable.updateDataByDate(params, (flag) => {
            if (!flag) {
                Logger.error('insertTaskSetting', 'updateTaskSetting Error!');
                reject(flag);
            }
            resolve(flag);
        })
        /*这里其实不应该将today的任务的isDone设置为true，这也是原程序中的一个bug：建立好任务后，回到主页面却发现该任务已经完成*/
        /*taskInfoTable.updateDataByDate({ ...params, date: TODAY, isDone: true }, (flag) => {
            if (!flag) {
                Logger.error('insertTaskSetting', 'updateTaskSetting Error!');
                reject(flag);
            }
            resolve(flag);
        })*/
    })
}

/**
 * @description Used to initialize task list data from database data
 * @param taskInitList Task list initial data
 * @param taskInfoData Database query data
 */
export const taskIndexDataInit = (taskInitList, taskInfoData) => {
    const afterInitData = taskInitList.map((content) => {
        taskInfoData.forEach((item) => {
            if (item?.taskID === content?.taskID) {
                content.isOpen = item?.isOpen;
                content.targetValue = item?.targetValue;
                content.isAlarm = item?.isAlarm;
                content.startTime = item?.startTime;
                content.endTime = item?.endTime;
                content.frequency = item?.frequency;
            }
        });
        return content;
    });
    return afterInitData;
}

/**
 * @description format data as json string
 * @param params = {}
 */
export const formatParams = (params = {}) => {
    return JSON.stringify(params);
}

/**
 * @description Initialization frequency string
 * @param frequencyIdCollection
 * @return string Frequency string
 */
export const initFrequencyString = (frequencyIdCollection) => {
    if (frequencyIdCollection === '') {
        return EVERYDAY;
    }
    const frequencyIdArray = frequencyIdCollection.split(',').map(item => Number(item));
    const length = frequencyIdArray.length;
    if (length === 7) {
        return EVERYDAY;
    }
    const frequencyString = frequencyIdArray.reduce((pre, current) => {
        return pre + ' ' + oneWeek[current];
    }, '')
    return frequencyString;
}

/**
 * @description Returns the timestamp of today's selected time
 * @param currentTime
 * @return timestamp
 */
export const returnTimeStamp = (currentTime: string) => {
    const timeString = `${TODAY} ${currentTime}`;
    return new Date(timeString).getTime();
}

/**
 * @description It is used for formatting time and displayed in the form of HH: mm
 * @param value
 */
export const formatTime = (value: TimePickerResult) => {
    return `${padTo2Digits(value?.hour)}:${padTo2Digits(value?.minute)}`;
}

/**
 * @description Range of generated drinking water 0.25 - 5 L
 * @return Array<string>
 */
export const createDrinkRange = () => {
    const drinkRangeArr = []
    for (let i = DRINK_STEP; i <= DRINK_MAX_RANGE; i += DRINK_STEP) {
        drinkRangeArr.push(`${i / TIMES_100} L`);
    }
    return drinkRangeArr;
}

/**
 * @description Generate the range of eating apples 1 - 100
 * @return Array<string>
 */
export const createAppleRange = () => {
    const appleRangeArr = []
    for (let i = 1; i <= EAT_APPLE_RANGE; i++) {
        appleRangeArr.push(`${i} 个`);
    }
    return appleRangeArr;
}