<template name="file-header">
    /*
        Generated by sbus code generator

        Copyright (C) 2017 Red Hat

        This program is free software; you can redistribute it and/or modify
        it under the terms of the GNU General Public License as published by
        the Free Software Foundation; either version 3 of the License, or
        (at your option) any later version.

        This program is distributed in the hope that it will be useful,
        but WITHOUT ANY WARRANTY; without even the implied warranty of
        MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
        GNU General Public License for more details.

        You should have received a copy of the GNU General Public License
        along with this program.  If not, see <http://www.gnu.org/licenses/>.
    */

    #include <errno.h>
    #include <talloc.h>
    #include <tevent.h>
    #include <dbus/dbus.h>

    #include "${sbus-path}/sbus_private.h"
    #include "${sbus-path}/sbus_interface_declarations.h"
    #include "${header:arguments}"
    #include "${header:invokers}"

    static errno_t
    sbus_invoker_schedule(TALLOC_CTX *mem_ctx,
                          struct tevent_context *ev,
                          void *handler,
                          void *private_data)
    {
        /* Schedule invoker as a timed event so it is processed after other
         * event types. This will give dispatcher a chance to catch more
         * messages before this invoker is triggered and therefore it will
         * allow to potentially chain more request into one, especially for
         * synchronous handlers. */

        struct tevent_timer *te;
        struct timeval tv;

        tv = tevent_timeval_current_ofs(0, 5);
        te = tevent_add_timer(ev, mem_ctx, tv, handler, private_data);
        if (te == NULL) {
            /* There is not enough memory to create a timer. We can't do
             * anything about it. */
            DEBUG(SSSDBG_OP_FAILURE, "Could not add invoker event!\n");
            return ENOMEM;
        }

        return EOK;
    }

</template>

<template name="invoker">
    struct _sbus_invoke_in_${input-signature}_out_${output-signature}_state {
        <toggle name="if-input-arguments">
        struct _sbus_invoker_args_${input-signature} *in;
        </toggle>
        <toggle name="if-output-arguments">
        struct _sbus_invoker_args_${output-signature} out;
        </toggle>
        struct {
            enum sbus_handler_type type;
            void *data;
            errno_t (*sync)(TALLOC_CTX *, struct sbus_request *, void *<loop name="in">, ${type}</loop><loop name="in-raw">, ${type}</loop><loop name="out">, ${type}</loop><loop name="out-raw">, ${type}</loop>);
            struct tevent_req * (*send)(TALLOC_CTX *, struct tevent_context *, struct sbus_request *, void *<loop name="in">, ${type}</loop><loop name="in-raw">, ${type}</loop><loop name="out-raw">, ${type}</loop>);
            errno_t (*recv)(TALLOC_CTX *, struct tevent_req *<loop name="out">, ${type}</loop>);
        } handler;

        struct sbus_request *sbus_req;
        DBusMessageIter *read_iterator;
        DBusMessageIter *write_iterator;
    };

    static void
    _sbus_invoke_in_${input-signature}_out_${output-signature}_step
        (struct tevent_context *ev,
         struct tevent_timer *te,
         struct timeval tv,
         void *private_data);

    static void
    _sbus_invoke_in_${input-signature}_out_${output-signature}_done
       (struct tevent_req *subreq);

    struct tevent_req *
    _sbus_invoke_in_${input-signature}_out_${output-signature}_send
       (TALLOC_CTX *mem_ctx,
        struct tevent_context *ev,
        struct sbus_request *sbus_req,
        sbus_invoker_keygen keygen,
        const struct sbus_handler *handler,
        DBusMessageIter *read_iterator,
        DBusMessageIter *write_iterator,
        const char **_key)
    {
        struct _sbus_invoke_in_${input-signature}_out_${output-signature}_state *state;
        struct tevent_req *req;
        const char *key;
        errno_t ret;

        req = tevent_req_create(mem_ctx, &state, struct _sbus_invoke_in_${input-signature}_out_${output-signature}_state);
        if (req == NULL) {
            DEBUG(SSSDBG_CRIT_FAILURE, "Unable to create tevent request!\n");
            return NULL;
        }

        state->handler.type = handler->type;
        state->handler.data = handler->data;
        state->handler.sync = handler->sync;
        state->handler.send = handler->async_send;
        state->handler.recv = handler->async_recv;

        state->sbus_req = sbus_req;
        state->read_iterator = read_iterator;
        state->write_iterator = write_iterator;

        <toggle name="if-input-arguments">
        state->in = talloc_zero(state, struct _sbus_invoker_args_${input-signature});
        if (state->in == NULL) {
            DEBUG(SSSDBG_CRIT_FAILURE,
                  "Unable to allocate space for input parameters!\n");
            ret = ENOMEM;
            goto done;
        }

        ret = _sbus_invoker_read_${input-signature}(state, read_iterator, state->in);
        if (ret != EOK) {
            goto done;
        }

        </toggle>
        ret = sbus_invoker_schedule(state, ev, _sbus_invoke_in_${input-signature}_out_${output-signature}_step, req);
        if (ret != EOK) {
            goto done;
        }

        ret = sbus_request_key(state, keygen, sbus_req,<toggle name="if-input-arguments"> state->in<or> NULL</toggle>, &key);
        if (ret != EOK) {
            goto done;
        }

        if (_key != NULL) {
            *_key = talloc_steal(mem_ctx, key);
        }

        ret = EAGAIN;

    done:
        if (ret != EAGAIN) {
            tevent_req_error(req, ret);
            tevent_req_post(req, ev);
        }

        return req;
    }

    static void _sbus_invoke_in_${input-signature}_out_${output-signature}_step
       (struct tevent_context *ev,
        struct tevent_timer *te,
        struct timeval tv,
        void *private_data)
    {
        struct _sbus_invoke_in_${input-signature}_out_${output-signature}_state *state;
        struct tevent_req *subreq;
        struct tevent_req *req;
        errno_t ret;

        req = talloc_get_type(private_data, struct tevent_req);
        state = tevent_req_data(req, struct _sbus_invoke_in_${input-signature}_out_${output-signature}_state);

        switch (state->handler.type) {
        case SBUS_HANDLER_SYNC:
            if (state->handler.sync == NULL) {
                DEBUG(SSSDBG_CRIT_FAILURE, "Bug: sync handler is not specified!\n");
                ret = ERR_INTERNAL;
                goto done;
            }

            ret = state->handler.sync(state, state->sbus_req, state->handler.data<loop name="in">, state->in->arg${index}</loop><loop name="in-raw">, state->read_iterator</loop><loop name="out">, &state->out.arg${index}</loop><loop name="out-raw">, state->write_iterator</loop>);
            if (ret != EOK) {
                goto done;
            }

            <toggle name="if-output-arguments">
            ret = _sbus_invoker_write_${output-signature}(state->write_iterator, &state->out);
            </toggle>
            goto done;
        case SBUS_HANDLER_ASYNC:
            if (state->handler.send == NULL || state->handler.recv == NULL) {
                DEBUG(SSSDBG_CRIT_FAILURE, "Bug: async handler is not specified!\n");
                ret = ERR_INTERNAL;
                goto done;
            }

            subreq = state->handler.send(state, ev, state->sbus_req, state->handler.data<loop name="in">, state->in->arg${index}</loop><loop name="in-raw">, state->read_iterator</loop><loop name="out-raw">, state->write_iterator</loop>);
            if (subreq == NULL) {
                DEBUG(SSSDBG_CRIT_FAILURE, "Unable to create subrequest!\n");
                ret = ENOMEM;
                goto done;
            }

            tevent_req_set_callback(subreq, _sbus_invoke_in_${input-signature}_out_${output-signature}_done, req);
            ret = EAGAIN;
            goto done;
        }

        ret = ERR_INTERNAL;

    done:
        if (ret == EOK) {
            tevent_req_done(req);
        } else if (ret != EAGAIN) {
            tevent_req_error(req, ret);
        }
    }

    static void _sbus_invoke_in_${input-signature}_out_${output-signature}_done(struct tevent_req *subreq)
    {
        struct _sbus_invoke_in_${input-signature}_out_${output-signature}_state *state;
        struct tevent_req *req;
        errno_t ret;

        req = tevent_req_callback_data(subreq, struct tevent_req);
        state = tevent_req_data(req, struct _sbus_invoke_in_${input-signature}_out_${output-signature}_state);

        ret = state->handler.recv(state, subreq<loop name="out">, &state->out.arg${index}</loop>);
        talloc_zfree(subreq);
        if (ret != EOK) {
            tevent_req_error(req, ret);
            return;
        }

        <toggle name="if-output-arguments">
        ret = _sbus_invoker_write_${output-signature}(state->write_iterator, &state->out);
        if (ret != EOK) {
            tevent_req_error(req, ret);
            return;
        }

        </toggle>
        tevent_req_done(req);
        return;
    }

</template>
