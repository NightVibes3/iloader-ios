import "./Certificates.css";
import { invoke } from "@tauri-apps/api/core";
import { useCallback, useEffect, useRef, useState } from "react";
import { toast } from "sonner";

type PairingAppInfo = {
  name: string;
  bundleId: string;
  path: string;
};

export const Pairing = () => {
  const [apps, setApps] = useState<PairingAppInfo[]>([]);

  const [loading, setLoading] = useState<boolean>(false);
  const loadingRef = useRef<boolean>(false);

  const loadApps = useCallback(async () => {
    if (loadingRef.current) return;
    const promise = async () => {
      loadingRef.current = true;
      setLoading(true);
      let list = await invoke<PairingAppInfo[]>("installed_pairing_apps");
      setApps(list);
      setLoading(false);
      loadingRef.current = false;
    };
    toast.promise(promise, {
      loading: "Loading Apps...",
      success: "Apps loaded successfully!",
      error: (e) => "Failed to load Apps: " + e,
    });
  }, [setApps]);

  const pair = useCallback(
    async (app: PairingAppInfo) => {
      const promise = invoke<void>("place_pairing_cmd", {
        bundleId: app.bundleId,
        path: app.path,
      });
      toast.promise(promise, {
        loading: "Placing pairing file...",
        success: "Pairing file placed successfully!",
        error: (e) => "Failed to place pairing: " + e,
      });
    },
    [setApps, loadApps]
  );

  useEffect(() => {
    loadApps();
  }, []);

  return (
    <>
      <h2>Manage Pairing File</h2>
      {apps.length === 0 ? (
        <div>{loading ? "Loading App..." : "No Supported Apps found."}</div>
      ) : (
        <div className="card">
          <div className="certificate-table-container">
            <table className="certificate-table">
              <thead>
                <tr className="certificate-item">
                  <th className="cert-item-part">Name</th>
                  <th className="cert-item-part">Bundle ID</th>
                  <th>Place Pairing File</th>
                </tr>
              </thead>
              <tbody>
                {apps.map((app, i) => (
                  <tr
                    key={app.bundleId}
                    className={
                      "certificate-item" +
                      (i === apps.length - 1 ? " cert-item-last" : "")
                    }
                  >
                    <td className="cert-item-part">{app.name}</td>
                    <td className="cert-item-part">{app.bundleId}</td>
                    <td className="cert-item-revoke" onClick={() => pair(app)}>
                      Place
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}
      <button
        style={{ marginTop: "1em" }}
        onClick={loadApps}
        disabled={loading}
      >
        Refresh
      </button>
    </>
  );
};
