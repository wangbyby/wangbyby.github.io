// #include<iostream>
// using namespace std;
 
// /* 后继 */
// int getNext(int i, int m, int n)
// {
//     return (i%n)*m + i/n;
// }
 
// /* 前驱 */
// int getPre(int i, int m, int n)
// {
//     return (i%m)*n + i/m;
// }

// void movedata(int *mtx, int i, int m, int n)
// {
//     int temp = mtx[i];  // 暂存
//     int cur = i;       // 当前下标
//     int pre = getPre(cur, m, n);
//     while(pre != i)
//     {
//         mtx[cur] = mtx[pre];
//         cur = pre;
//         pre = getPre(cur, m, n);
//     }
//     mtx[cur] = temp;
// }

// void transpose(int *mtx, int m, int n)
// {
//     for(int i=0; i<m*n; ++i)
//     {
//         int next = getNext(i, m, n);
//         while(next > i) // 若存在后继小于i说明重复
//             next = getNext(next, m, n);
//         if(next == i)   // 处理当前环 
//             movedata(mtx, i, m, n);
//     }
// }
 
// /* 输出矩阵 */
// void print(int *mtx, int m, int n)
// {
//     for(int i=0; i<m*n; ++i)
//     {
//         if((i+1)%n == 0)
//             cout << mtx[i] << "\n";
//         else
//             cout << mtx[i] << " ";
//     }
// }

// int main()
// {
//     constexpr int rows = 1;
//     constexpr int cols = 10;

//     int matrix[rows*cols]  ;
//     for(int i=1;i<= rows*cols;i++){
//         matrix[i-1] = i;
//     }

//     cout << "Before matrix transposition:" << endl;
//     print(matrix, rows, cols);
//     transpose(matrix, rows, cols);
//     cout << "After matrix transposition:" << endl;
//     print(matrix, cols, rows);
//     return 0;
// }


#include <functional>
#include <queue>
#include <vector>

using namespace std ;
class Solution {
public:
    vector<int> maxSlidingWindow(vector<int>& nums, int k) {
        
       vector<int> res;
        deque<int> queue;

        for(int i=0;i<nums.size();i++){
            int num = nums[i];
            
            while(queue.size() > k ){
                queue.pop_front();
            }
            while(queue.size() && num > nums[queue.back ()] ){
                queue.pop_back();
            }

            queue.push_back(i);
            if(i >= k-1){
                res.push_back(nums[ queue.front() ]);
            }

        }   
        return res;
    }
};