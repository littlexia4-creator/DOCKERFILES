#include <asio.hpp>
#include <iostream>

int main() {
    asio::io_context io;
    std::cout << "asio version: " << ASIO_VERSION << '\n';
    return 0;
}
