use serde::Serialize;
use tauri::{Emitter, Window};

pub struct Operation<'a> {
    id: String,
    window: &'a Window,
}

#[derive(Clone, Serialize)]
#[serde(rename_all = "camelCase")]
struct OperationUpdate<'a> {
    update_type: &'a str,
    step_id: &'a str,
    extra_details: Option<String>,
}

impl<'a> Operation<'a> {
    pub fn new(id: String, window: &'a Window) -> Operation<'a> {
        Operation { id, window }
    }

    pub fn move_on(&self, old_id: &str, new_id: &str) -> Result<(), String> {
        self.complete(old_id)?;
        self.start(new_id)
    }

    pub fn start(&self, id: &str) -> Result<(), String> {
        self.window
            .emit(
                &format!("operation_{}", self.id),
                OperationUpdate {
                    update_type: "started",
                    step_id: id,
                    extra_details: None,
                },
            )
            .map_err(|_| "Failed to emit status to frontend".to_string())
    }

    pub fn complete(&self, id: &str) -> Result<(), String> {
        self.window
            .emit(
                &format!("operation_{}", self.id),
                OperationUpdate {
                    update_type: "finished",
                    step_id: id,
                    extra_details: None,
                },
            )
            .map_err(|_| "Failed to emit status to frontend".to_string())
    }

    pub fn fail<T>(&self, id: &str, error: String) -> Result<T, String> {
        self.window
            .emit(
                &format!("operation_{}", self.id),
                OperationUpdate {
                    update_type: "failed",
                    step_id: id,
                    extra_details: Some(error.clone()),
                },
            )
            .map_err(|_| "Failed to emit status to frontend".to_string())?;
        Err(error)
    }

    pub fn fail_if_err<T>(&self, id: &str, res: Result<T, String>) -> Result<T, String> {
        match res {
            Ok(t) => Ok(t),
            Err(e) => self.fail::<T>(id, e),
        }
    }
}
