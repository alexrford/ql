/**
 * Provides a taint-tracking configuration for reasoning about user-controlled bypass of sensitive
 * methods.
 */
import csharp

module UserControlledBypassOfSensitiveMethod {
  import semmle.code.csharp.controlflow.Guards
  import semmle.code.csharp.controlflow.BasicBlocks
  import semmle.code.csharp.dataflow.flowsources.Remote
  import semmle.code.csharp.frameworks.System
  import semmle.code.csharp.frameworks.system.Net
  import semmle.code.csharp.security.SensitiveActions

  /**
   * A data flow source for user-controlled bypass of sensitive method.
   */
  abstract class Source extends DataFlow::Node { }

  /**
   * A data flow sink for user-controlled bypass of sensitive method.
   */
  abstract class Sink extends DataFlow::ExprNode {
    /** Gets the 'MethodCall' which is considered sensitive. */
    abstract MethodCall getSensitiveMethodCall();
  }

  /**
   * A sanitizer for user-controlled bypass of sensitive method.
   */
  abstract class Sanitizer extends DataFlow::ExprNode { }

  /**
   * A taint-tracking configuration for user-controlled bypass of sensitive method.
   */
  class Configuration extends TaintTracking::Configuration {
    Configuration() {
      this = "UserControlledBypassOfSensitiveMethodConfiguration"
    }

    override
    predicate isSource(DataFlow::Node source) {
      source instanceof Source
    }

    override
    predicate isSink(DataFlow::Node sink) {
      sink instanceof Sink
    }

    override
    predicate isSanitizer(DataFlow::Node node) {
      node instanceof Sanitizer
    }
  }

  /** A source of remote user input. */
  class RemoteSource extends Source {
    RemoteSource() {
      this instanceof RemoteFlowSource
    }
  }

  /** The result of a reverse dns may be user-controlled. */
  class ReverseDnsSource extends Source {
    ReverseDnsSource() {
      this.asExpr().(MethodCall).getTarget() = any(SystemNetDnsClass dns).getGetHostByAddressMethod()
    }
  }

  /**
   * Calls to a sensitive method that are controlled by a condition
   * on the given expression.
   */
  predicate conditionControlsMethod(MethodCall call, Expr e) {
    exists (ConditionBlock cb, SensitiveExecutionMethod def, boolean cond |
      cb.controls(call.getAControlFlowNode().getBasicBlock(), cond) and
      def = call.getTarget() and
      /*
       * Exclude this condition if the other branch also contains a call to the same security
       * sensitive method.
       */
      not cb.controls(def.getACall().getAControlFlowNode().getBasicBlock(), cond.booleanNot()) and
      e = cb.getLastNode().getElement()
    )
  }

  /**
   * An expression which is a condition which controls access to a sensitive action.
   */
  class ConditionControllingSensitiveAction extends Sink {
    private MethodCall sensitiveMethodCall;
    ConditionControllingSensitiveAction() {
      // A condition used to guard a sensitive method call
      conditionControlsMethod(sensitiveMethodCall, this.getExpr()) or
      /*
       * A condition used to guard a sensitive method call, where the condition is `EndsWith`,
       * `StartsWith` or `Contains` on a tainted value. Tracking from strings to booleans doesn't
       * make sense in all contexts, so this is restricted to this case.
       */
      exists(MethodCall stringComparisonCall, string methodName |
        methodName = "EndsWith" or
        methodName = "StartsWith" or
        methodName = "Contains" |
        stringComparisonCall = any(SystemStringClass s).getAMethod(methodName).getACall() and
        conditionControlsMethod(sensitiveMethodCall, stringComparisonCall) and
        stringComparisonCall.getQualifier() = this.getExpr()
      )
    }

    override
    MethodCall getSensitiveMethodCall() {
      result = sensitiveMethodCall
    }
  }
}
