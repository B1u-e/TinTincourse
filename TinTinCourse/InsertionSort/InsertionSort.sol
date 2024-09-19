// 声明合约使用的许可证为MIT许可证  
// SPDX-License-Identifier: MIT   
pragma solidity ^0.8.0;

//插入排序算法

contract InsertionSort {
    uint256[] private Array;

    // 对数组进行插入排序并保存结果
    function sortAndStore(uint256[] memory arr) public {
        uint256 n = arr.length;

        for (uint256 i = 1; i < n; ++i) {
            
            uint256 key = arr[i];
            uint256 j = i;  //从i开始

            // 将key插入到已排序部分的正确位置  
            while (j > 0 && arr[j - 1] > key) {
                arr[j] = arr[j - 1]; // 向右移动元素
                j--;   //将j减1，继续比较前一个元素  
            }
            arr[j] = key; // 插入key
        }
        Array = arr; // 保存排序后的数组
    }

    // 查询排序后的数组
    function getArray() public view returns (uint256[] memory) {
        return Array;
    }
}