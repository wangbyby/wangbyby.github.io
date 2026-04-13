

#include <memory>
struct A{
    int a;
    char* c;
};

class B{
    private:
    int a;
    public:
        int b;
        char*c;
};

int main(){
    A a{1,0};
    std::shared_ptr<int> s;
    B b{2,nullptr};
}