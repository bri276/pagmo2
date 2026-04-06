/* Copyright 2017-2021 PaGMO development team

This file is part of the PaGMO library.

The PaGMO library is free software; you can redistribute it and/or modify
it under the terms of either:

  * the GNU Lesser General Public License as published by the Free
    Software Foundation; either version 3 of the License, or (at your
    option) any later version.

or

  * the GNU General Public License as published by the Free Software
    Foundation; either version 3 of the License, or (at your option) any
    later version.

or both in parallel, as here.

The PaGMO library is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
for more details.

You should have received copies of the GNU General Public License and the
GNU Lesser General Public License along with the PaGMO library.  If not,
see https://www.gnu.org/licenses/. */

#ifndef PAGMO_CAST_HPP
#define PAGMO_CAST_HPP

#include <limits>
#include <stdexcept>
#include <string>
#include <sstream>

namespace pagmo
{

// Source - https://stackoverflow.com/a/49658950
// Posted by Trevor Boyd Smith, modified by community. See post 'Timeline' for change history
// Retrieved 2026-04-06, License - CC BY-SA 4.0

template <typename U, typename T>
inline U numeric_cast(T value)
{
    typedef std::numeric_limits<U> ULim;
    typedef std::numeric_limits<T> TLim;

    const bool positive_overflow_possible = ULim::max() < TLim::max();
    const bool negative_overflow_possible = TLim::is_signed or (ULim::lowest() > TLim::lowest());

    // unsigned <-- unsigned
    if ((not ULim::is_signed) and (not TLim::is_signed)) {
        if (positive_overflow_possible and (value > ULim::max())) {
            throw std::overflow_error(__PRETTY_FUNCTION__ + std::string(": positive overflow"));
        }
    }
    // unsigned <-- signed
    else if ((not ULim::is_signed) and TLim::is_signed) {
        if (positive_overflow_possible and (value > ULim::max())) {
            throw std::overflow_error(__PRETTY_FUNCTION__ + std::string(": positive overflow"));
        } else if (negative_overflow_possible and (value < 0)) {
            throw std::overflow_error(__PRETTY_FUNCTION__ + std::string(": negative overflow"));
        }

    }
    // signed <-- unsigned
    else if (ULim::is_signed and (not TLim::is_signed)) {
        if (positive_overflow_possible and (value > ULim::max())) {
            throw std::overflow_error(__PRETTY_FUNCTION__ + std::string(": positive overflow"));
        }
    }
    // signed <-- signed
    else if (ULim::is_signed and TLim::is_signed) {
        if (positive_overflow_possible and (value > ULim::max())) {
            throw std::overflow_error(__PRETTY_FUNCTION__ + std::string(": positive overflow"));
        } else if (negative_overflow_possible and (value < ULim::lowest())) {
            throw std::overflow_error(__PRETTY_FUNCTION__ + std::string(": negative overflow"));
        }
    }

    // limits have been checked, therefore safe to cast
    return static_cast<U>(value);
}

template <typename T>
std::string lexical_cast(const T &value)
{
    std::ostringstream oss;
    oss << value;
    return oss.str();
}

} // namespace pagmo

#endif