#include <iostream>
#include "simpl-driver.hpp"

int main(int argc, char* argv[])
{
    int res = 0;
    Simpl_driver driver;
    driver.AST_dumping = false;
    driver.XML_dumping = false;
    driver.XML_dumping_path = "";

    for (auto i = 1; i < argc; ++i)
    {
        if (argv[i] == std::string("-ast"))
        {
            driver.AST_dumping = true;
        }
        else if (argv[i] == std::string("-xml") && i < argc - 1)
        {
            driver.XML_dumping = true;
            driver.XML_dumping_path = std::string(argv[++i]);
        }
        else if (!driver.parse(argv[i]))
        {
            std::cout << driver.result << std::endl;
        }
        else
        {
            res = 1;
        }
    }
    return res;
}
