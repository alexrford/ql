/**
 * @name Non-virtual destructor
 * @description When a class and its derived class both define non-virtual
 *              destructors, the destructor of the derived class may not
 *              always be called.
 * @kind problem
 * @id cpp/non-virtual-destructor
 * @problem.severity warning
 * @tags reliability
 */

// This query is deprecated, and replaced by jsf/4.10 Classes/AV Rule 78.ql, which has far fewer false positives on typical code.

import cpp

from Class base, Destructor d1, Class derived, Destructor d2
where derived.getABaseClass+() = base and
      d1.getDeclaringType() = base and
      not d1.isVirtual() and
      d2.getDeclaringType() = derived
select d1, "This destructor should probably be virtual."
