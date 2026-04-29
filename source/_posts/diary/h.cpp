
/**
 * Definition for singly-linked list.
 * struct ListNode {
 *     int val;
 *     ListNode *next;
 *     ListNode() : val(0), next(nullptr) {}
 *     ListNode(int x) : val(x), next(nullptr) {}
 *     ListNode(int x, ListNode *next) : val(x), next(next) {}
 * };
 */
#include <queue>
#include <vector>
struct ListNode {
  int val;
  ListNode *next;
  ListNode() : val(0), next(nullptr) {}
  ListNode(int x) : val(x), next(nullptr) {}
  ListNode(int x, ListNode *next) : val(x), next(next) {}
};

class Solution {
public:
  class Cmp {
  public:
    bool operator()(const ListNode *a, const ListNode *b) {
      return a->val > b->val;
    }
  };
  ListNode *mergeKLists(std::vector<ListNode *> &lists) {
    std::priority_queue<ListNode *, std::vector<ListNode *>, Cmp> pk;
    int k = lists.size();

    for (auto *i : lists) {
      if (i) {
        pk.push(i);
      }
    }
    ListNode pesudo;
    auto *iter = &pesudo;

    while (pk.size()) {
      auto *n = pk.top();
      pk.pop();

      auto *next = n->next;
      if (next) {
        pk.push(next);
      }
      iter->next = n;
      iter = n;
    }
    return pesudo.next;
  }
};