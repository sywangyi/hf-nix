final: prev:

{
  # Hook to mark packages for XPU root setup
  markForXpuRootHook = prev.makeSetupHook {
    name = "mark-for-xpu-root-hook";
  } ./mark-for-xpu-root-hook.sh;

  # Setup hook for XPU environment
  setupXpuHook = prev.makeSetupHook {
    name = "setup-xpu-hook";
  } ./setup-xpu-hook.sh;
}
